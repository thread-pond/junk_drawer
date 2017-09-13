# frozen_string_literal: true

require 'active_support/all'
require 'active_record'
require 'active_record/connection_adapters/postgresql_adapter'

module JunkDrawer
  # module to allow bulk updates for `ActiveRecord` models
  module BulkUpdatable
    ATTRIBUTE_TYPE_TO_POSTGRES_CAST = {
      datetime: '::timestamp',
      hstore: '::hstore',
      boolean: '::boolean',
      jsonb: '::jsonb',
    }.freeze

    POSTGRES_VALUE_CASTERS = {
      hstore: ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Hstore.new,
      jsonb: ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Jsonb.new,
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
      postgres_types = attributes.map do |attribute|
        attribute_type = columns_hash[attribute.to_s].type
        "?#{ATTRIBUTE_TYPE_TO_POSTGRES_CAST[attribute_type]}"
      end

      postgres_values = attributes.map do |attribute|
        value = object[attribute]
        attribute_type = columns_hash[attribute.to_s].type
        caster = POSTGRES_VALUE_CASTERS[attribute_type]

        caster ? serialized_value(caster, value) : value
      end

      sanitize_sql_array(
        ["(?, #{postgres_types.join(', ')})", object.id, *postgres_values],
      )
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
