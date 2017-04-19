# frozen_string_literal: true

module JunkDrawer
  # error to be thrown by Callable
  class CallableError < StandardError
  end

  # module to constrain interfaces of classes to just `call`
  module Callable
    def call
      raise NotImplementedError
    end

    def to_proc
      proc { |args| self.(*args) }
    end

    # `ClassMethods` defines a class level method `call` that delegates to
    # an instance. It also causes an error to be raised if a public instance
    # method is defined with a name other than `call`
    module ClassMethods
      def call(*args)
        new.(*args)
      end

      def to_proc
        new.to_proc
      end

      def method_added(method_name)
        return if valid_callable_method?(method_name)

        raise CallableError, "invalid method name #{method_name}, " \
                            'only public method allowed is "call"'
      end

    private

      def valid_callable_method?(method_name)
        method_name == :call ||
          !public_method_defined?(method_name) ||
          method_name.to_s.start_with?('__')
      end
    end

    def self.included(base)
      base.public_send(:extend, ClassMethods)
    end
  end
end
