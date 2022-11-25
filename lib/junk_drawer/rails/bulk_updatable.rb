# frozen_string_literal: true

require 'active_support/all'
require 'active_record'
require 'active_record/connection_adapters/postgresql_adapter'

module JunkDrawer
  # module to allow bulk updates for `ActiveRecord` models
  module BulkUpdatable
    def bulk_update(objects)
      objects = objects.select(&:changed?)
      return unless objects.any?

      unique_objects = uniquify_and_merge(objects)
      changed_attributes = extract_changed_attributes(unique_objects)
      query = build_query_for(unique_objects, changed_attributes)
      connection.execute(query)
      objects.each(&:changes_applied)
    end

  private

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
      if ::ActiveRecord::VERSION::MAJOR >= 5
        column_names & changed_attributes
      else
        # to remove virtual columns from jsonb_accessor 0.3.3
        columns.select(&:sql_type).map(&:name) & changed_attributes
      end
    end

    def build_query_for(objects, attributes)
      object_values = objects.map do |object|
        sanitized_values(object, attributes)
      end.join(', ')

      assignment_query = attributes.map do |attribute|
        quoted_column_name = connection.quote_column_name(attribute)
        "#{quoted_column_name} = tmp_table.#{quoted_column_name}"
      end.join(', ')

      "UPDATE #{table_name} " \
      "SET #{assignment_query} " \
      "FROM (VALUES #{object_values}) " \
      "AS tmp_table(id, #{attributes.join(', ')}) " \
      "WHERE #{table_name}.id = tmp_table.id"
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

        "#{connection.quote(serialized_value(type, value))}#{type_cast}"
      end

      "(#{[object.id, *postgres_values].join(', ')})"
    end

    def serialized_value(type, value)
      if ::ActiveRecord::VERSION::MAJOR >= 5
        type.serialize(value)
      else
        type.type_cast_for_database(value)
      end
    end
  end
end
