# frozen_string_literal: true

require_relative 'junk_drawer/callable'
require_relative 'junk_drawer/notifier'
require_relative 'junk_drawer/version'

# namespace for all JunkDrawer code
module JunkDrawer
  class NotifierError < StandardError
  end
end
