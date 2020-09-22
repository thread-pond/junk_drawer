# frozen_string_literal: true

# rubocop:disable Style/EmptyLinesAroundClassBody
RSpec.describe JunkDrawer::Callable do
  after do
    if Object.const_defined?(:MyCallableClass)
      Object.__send__(:remove_const, :MyCallableClass)
    end
  end

  it 'adds a class method which delegates to an instance' do
    class MyCallableClass
      include JunkDrawer::Callable
      def call(one_arg, who:)
        "calling in, #{one_arg} who #{who}"
      end
    end

    expected = 'calling in, what who cares'
    expect(MyCallableClass.('what', who: 'cares')).to eq expected
  end

  it 'handles default arguments' do
    class MyCallableClass
      include JunkDrawer::Callable
      def call(one_arg = 'foo')
        "calling in, #{one_arg}"
      end
    end

    expected = 'calling in, foo'
    expect(MyCallableClass.()).to eq expected
  end

  it 'passes through a block to the instance method' do
    class MyCallableClass
      include JunkDrawer::Callable
      def call
        yield 'foo block content'
      end
    end

    actual = nil
    MyCallableClass.() { |result| actual = result }
    expect(actual).to eq 'foo block content'
  end

  it 'throws an error when call method is not defined' do
    class MyCallableClass
      include JunkDrawer::Callable
    end

    expect do
      MyCallableClass.()
    end.to raise_error(NotImplementedError)
  end

  it 'throws an error when another public method is defined' do
    expect do
      class MyCallableClass
        include JunkDrawer::Callable

        def bad_meth; end
      end
    end.to raise_error(JunkDrawer::CallableError, /invalid method.*bad_meth/)
  end

  it 'allows private methods to be defined' do
    expect do
      class MyCallableClass
        include JunkDrawer::Callable

      private

        def good_meth; end
      end
    end.not_to raise_error
  end

  describe '#to_proc', '.to_proc' do
    it 'returns a proc wrapping the call method' do
      class MyCallableClass
        include JunkDrawer::Callable

        def call(arg)
          arg * 2
        end
      end

      expect([1, 2, 3].map(&MyCallableClass.new)).to eq [2, 4, 6]
      expect([1, 2, 3].map(&MyCallableClass)).to eq [2, 4, 6]
    end

    it 'passes through multiple arguments' do
      class MyCallableClass
        include JunkDrawer::Callable

        def call(arg_1, arg_2)
          "#{arg_1} : #{arg_2}"
        end
      end

      expected = ['a : b', 'c : d']
      expect([%w[a b], %w[c d]].map(&MyCallableClass.new)).to eq expected
      expect([%w[a b], %w[c d]].map(&MyCallableClass)).to eq expected
    end

    it 'copes gracefully with RSpec any_instance matchers' do
      class MyCallableClass
        include JunkDrawer::Callable

        def call
          'whatevs'
        end
      end

      expect do
        # rubocop:disable RSpec/AnyInstance
        klass = MyCallableClass
        allow_any_instance_of(klass).to receive(:call).and_return('thanks')
        expect_any_instance_of(klass).to receive(:call).and_return('thanks')
        # rubocop:enable RSpec/AnyInstance
      end.not_to raise_error

      expect(MyCallableClass.()).to eq 'thanks'
    end
  end
end
