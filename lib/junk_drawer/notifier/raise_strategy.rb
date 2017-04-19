# frozen_string_literal: true

module JunkDrawer
  class Notifier

    # Notifier strategy to raise an error when notification is triggered
    class RaiseStrategy

      include Callable

      def call(message, **context)
        raise NotifierError, "#{message}, context: #{context}"
      end

    end

  end
end
