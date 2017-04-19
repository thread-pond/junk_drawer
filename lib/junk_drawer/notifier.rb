# frozen_string_literal: true

require_relative 'notifier/honeybadger_strategy'
require_relative 'notifier/null_strategy'
require_relative 'notifier/raise_strategy'

module JunkDrawer
  # class to send dev notifications to different channels
  class Notifier

    include Callable

    class << self

      attr_accessor :strategy

    end

    STRATEGIES = {
      honeybadger: HoneybadgerStrategy,
      raise: RaiseStrategy,
      null: NullStrategy,
    }.freeze

    def call(*args)
      strategy.(*args)
    end

  private

    def strategy
      STRATEGIES.fetch(self.class.strategy)
    end

  end
end
