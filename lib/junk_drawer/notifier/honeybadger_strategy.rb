# frozen_string_literal: true

module JunkDrawer
  class Notifier

    # Notifier strategy to send a notification to Honeybadger
    class HoneybadgerStrategy

      include Callable

      def call(message, **context)
        error = message.is_a?(Exception) ? message : NotifierError.new(message)
        Honeybadger.notify(error, context: context)
      end

    end

  end
end
