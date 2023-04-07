# frozen_string_literal: true

module JunkDrawer
  module Matchers
    class Invoke

      include RSpec::Matchers::Composable

      def initialize(expected_method)
        @expected_method = expected_method
      end

      def failure_message
        received_matcher.failure_message
      end

      def failure_message_when_negated
        received_matcher.failure_message_when_negated
      end

      def matches?(event_proc)
        raise "missing '.on'" unless defined?(@expected_recipient)

        allow(@expected_recipient).to receive(@expected_method)
        allow(@expected_recipient).to receive_expected
        event_proc.()
        received_matcher.matches?(@expected_recipient)
      end

      def on(expected_recipient)
        @expected_recipient = expected_recipient
        self
      end

      def with(*expected_arguments)
        @expected_arguments = expected_arguments
        self
      end

      def and_return(*return_arguments)
        @return_arguments = return_arguments
        self
      end

      def and_call_original
        @and_call_original = true
        self
      end

      def supports_block_expectations?
        true
      end

    private

      def receive_expected
        receive_expected = receive(@expected_method)
        receive_expected = receive_expected.and_return(*@return_arguments) if defined?(@return_arguments)

        receive_expected = receive_expected.and_call_original if defined?(@and_call_original)
        receive_expected
      end

      def allow(target)
        RSpec::Mocks::AllowanceTarget.new(target)
      end

      def receive(method_name)
        RSpec::Mocks::Matchers::Receive.new(method_name, nil)
      end

      def received_matcher
        @received_matcher ||= begin
          matcher = RSpec::Mocks::Matchers::HaveReceived.new(@expected_method)
          matcher = matcher.with(*@expected_arguments) if defined?(@expected_arguments)

          matcher
        end
      end

    end
  end
end

def invoke(expected_method)
  JunkDrawer::Matchers::Invoke.new(expected_method)
end
