# frozen_string_literal: true

module JunkDrawer
  class Notifier

    # Notifier strategy to silently swallow notifications and do nothing
    class NullStrategy

      include Callable

      def call(*); end

    end

  end
end
