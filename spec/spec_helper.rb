# frozen_string_literal: true

require 'with_model'

require_relative '../lib/junk_drawer/rails'
Dir['./spec/support/**/*.rb'].each { |file_path| require file_path }

Time.zone = 'Eastern Time (US & Canada)'

ActiveRecord::Base.establish_connection(
  username: 'postgres',
  password: 'postgres',
  adapter: 'postgresql',
  database: 'junk_drawer_test',
  host: 'localhost',
)
ActiveRecord::Base.connection.execute('CREATE EXTENSION IF NOT EXISTS hstore;')

RSpec.configure do |config|
  config.order = :random
  config.filter_run_when_matching :focus

  config.extend(WithModel)
end

RSpec::Matchers.define_negated_matcher :not_change, :change
