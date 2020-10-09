# frozen_string_literal: true

require_relative 'notifier/honeybadger_strategy'
require_relative 'notifier/null_strategy'
require_relative 'notifier/raise_strategy'

module JunkDrawer
  # class to send dev notifications to different channels
  class Notifier

    include Callable

    class << self

      attr_reader :strategy

      def strategy=(strategy)
        @strategy =
          strategy.is_a?(Symbol) ? STRATEGIES.fetch(strategy) : strategy
      end

    end

    STRATEGIES = {
      honeybadger: HoneybadgerStrategy,
      raise: RaiseStrategy,
      null: NullStrategy,
    }.freeze

    def call(*args)
      self.class.strategy.(*args)
    end

  end
end
