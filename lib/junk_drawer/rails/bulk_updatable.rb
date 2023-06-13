# frozen_string_literal: true

require 'active_support/all'
require 'active_record'
require 'active_record/connection_adapters/postgresql_adapter'
require 'active_record/relation/query_attribute'

module JunkDrawer
  # module to allow bulk updates for `ActiveRecord` models
  module BulkUpdatable
    def bulk_update(objects)
      objects = objects.select(&:changed?)
      return unless objects.any?

      if connection.prepared_statements
        build_and_exec_prepared_query(objects)
      else
        build_and_exec_unprepared_query(objects)
      end
      objects.each(&:changes_applied)
    end

  private

    def build_and_exec_prepared_query(objects)
      unique_objects = uniquify_and_merge(objects)
      changed_attributes = extract_changed_attributes(unique_objects)
      attributes = ['id'] + changed_attributes

      unique_objects.each_slice(batch_size(attributes)) do |batch|
        query = build_prepared_query_for(batch, attributes, changed_attributes)
        values = values_for_objects(batch, attributes)
        connection.exec_query(query, "#{name} Bulk Update", values, prepare: true)
      end
    end

    def build_and_exec_unprepared_query(objects)
      unique_objects = uniquify_and_merge(objects)
      changed_attributes = extract_changed_attributes(unique_objects)
      query = build_unprepared_query_for(unique_objects, changed_attributes)
      connection.execute(query)
    end

    def uniquify_and_merge(objects)
      grouped_objects = objects.group_by(&:id).values
      grouped_objects.each do |group|
        next if group.length == 1

        attrs = group.each_with_object({}) do |object, changes|
          object.changed.each do |changed_attribute|
            changes[changed_attribute] = object[changed_attribute]
          end
        end
        group.each { |object| object.attributes = attrs }
      end
      grouped_objects.map(&:first)
    end

    def extract_changed_attributes(objects)
      now = Time.zone.now
      objects.each { |object| object.updated_at = now }

      changed_attributes = objects.flat_map(&:changed).uniq
      column_names & changed_attributes
    end

    def build_unprepared_query_for(objects, attributes)
      object_values = objects.map { |object| sanitized_values(object, attributes) }
      build_query_for(attributes, object_values.join(', '))
    end

    def build_prepared_query_for(objects, attributes, changed_attributes)
      object_placeholders = build_placeholders(objects, attributes)
      build_query_for(changed_attributes, object_placeholders)
    end

    def build_query_for(attributes, values)
      assignment_query = attributes.map do |attribute|
        quoted_column_name = connection.quote_column_name(attribute)
        "#{quoted_column_name} = tmp_table.#{quoted_column_name}"
      end.join(', ')

      "UPDATE #{table_name} " \
      "SET #{assignment_query} " \
      "FROM (VALUES #{values}) " \
      "AS tmp_table(id, #{attributes.join(', ')}) " \
      "WHERE #{table_name}.id = tmp_table.id"
    end

    def build_placeholders(objects, attributes)
      index = 0
      objects.map do
        attribute_placeholders = attributes.map do |attribute|
          index += 1
          attribute_placeholder(attribute, index)
        end.join(', ')

        "(#{attribute_placeholders})"
      end.join(', ')
    end

    def attribute_placeholder(attribute, index)
      # AR internal `columns_hash`
      column = columns_hash[attribute.to_s]

      type_cast = "::#{column.sql_type}"
      type_cast = "#{type_cast}[]" if column.array

      "$#{index}#{type_cast}"
    end

    def values_for_objects(objects, attributes)
      objects.flat_map { |object| values_for_object(object, attributes) }
    end

    def values_for_object(object, attributes)
      attributes.map do |attribute|
        value = object[attribute]

        # AR internal `columns_hash`
        column = columns_hash[attribute.to_s]

        # AR internal `type_for_attribute`
        type = type_for_attribute(column.name)
        ActiveRecord::Relation::QueryAttribute.new(column.name, value, type)
      end
    end

    def sanitized_values(object, attributes)
      postgres_values = attributes.map do |attribute|
        value = object[attribute]

        # AR internal `columns_hash`
        column = columns_hash[attribute.to_s]

        # AR internal `type_for_attribute`
        type = type_for_attribute(column.name)
        type_cast = "::#{column.sql_type}"
        type_cast = "#{type_cast}[]" if column.array

        "#{connection.quote(type.serialize(value))}#{type_cast}"
      end

      "(#{[object.id, *postgres_values].join(', ')})"
    end

    def batch_size(attribute_names)
      max_bind_params = connection.__send__(:bind_params_length)
      max_bind_params / attribute_names.length
    end
  end
end
