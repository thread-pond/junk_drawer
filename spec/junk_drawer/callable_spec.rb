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

        def bad_meth
        end
      end
    end.to raise_error(JunkDrawer::CallableError, /invalid method.*bad_meth/)
  end

  it 'allows private methods to be defined' do
    expect do
      class MyCallableClass
        include JunkDrawer::Callable

      private

        def good_meth
        end
      end
    end.not_to raise_error
  end
end
