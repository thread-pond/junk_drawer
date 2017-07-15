# frozen_string_literal: true

require 'with_model'

require_relative '../lib/junk_drawer/rails'
require_relative 'support/invoke_matcher'

Time.zone = 'Eastern Time (US & Canada)'

ActiveRecord::Base.establish_connection(
  username: 'postgres',
  adapter: 'postgresql',
  database: 'junk_drawer_test',
  host: 'localhost',
)

RSpec.configure do |config|
  config.order = :random
  config.filter_run_when_matching :focus

  config.extend(WithModel)
end

RSpec::Matchers.define_negated_matcher :not_change, :change
