# frozen_string_literal: true

require_relative '../lib/junk_drawer'
require_relative 'support/invoke_matcher'

RSpec.configure do |config|
  config.order = :random
  config.filter_run_when_matching :focus
end
