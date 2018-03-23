# frozen_string_literal: true

require 'active_support/all'
require 'active_record'
require 'active_record/connection_adapters/postgresql_adapter'

module JunkDrawer
  # module to allow bulk updates for `ActiveRecord` models
  module BulkUpdatable
    ATTRIBUTE_TYPE_TO_POSTGRES_CAST = {
      boolean: '::boolean',
      date: '::date',
      datetime: '::timestamp',
      float: '::float',
      hstore: '::hstore',
      integer: '::int',
      json: '::json',
      jsonb: '::jsonb',
      decimal: '::decimal',
      string: '::text',
      text: '::text',
      time: '::time',
      uuid: '::uuid',
    }.freeze

    def bulk_update(objects)
      objects = objects.select(&:changed?)
      return unless objects.any?

      changed_attributes = extract_changed_attributes(objects)
      query = build_query_for(objects, changed_attributes)
      connection.execute(query)
    end

  private

    def extract_changed_attributes(objects)
      now = Time.zone.now
      objects.each { |object| object.updated_at = now }

      objects.flat_map(&:changed).uniq
    end

    def build_query_for(objects, attributes)
      object_values = objects.map do |object|
        sanitized_values(object, attributes)
      end.join(', ')

      assignment_query = attributes.map do |attribute|
        quoted_column_name = connection.quote_column_name(attribute)
        "#{quoted_column_name} = tmp_table.#{quoted_column_name}"
      end.join(', ')

      <<-SQL
        UPDATE #{table_name}
        SET #{assignment_query}
        FROM (VALUES #{object_values}) AS tmp_table(id, #{attributes.join(', ')})
        WHERE #{table_name}.id = tmp_table.id
      SQL
    end

    def sanitized_values(object, attributes)
      postgres_values = attributes.map do |attribute|
        value = object[attribute]
        column = columns_hash[attribute.to_s]
        caster = type_for_attribute(column.name)
        type_cast = ATTRIBUTE_TYPE_TO_POSTGRES_CAST.fetch(column.type)

        "#{connection.quote(serialized_value(caster, value))}#{type_cast}"
      end

      "(#{[object.id, *postgres_values].join(', ')})"
    end

    def serialized_value(caster, value)
      if ::ActiveRecord::VERSION::MAJOR >= 5
        caster.serialize(value)
      else
        caster.type_cast_for_database(value)
      end
    end
  end
end
