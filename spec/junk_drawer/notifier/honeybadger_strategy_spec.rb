# frozen_string_literal: true

RSpec.describe JunkDrawer::Notifier::HoneybadgerStrategy, '#call' do
  let(:strategy) { described_class.new }

  class FakeHoneybadger

    def notify(error, options); end

  end

  before { stub_const('Honeybadger', FakeHoneybadger) }

  it 'notifies honeybadger with a NotifierError when given a string message' do
    message = 'foobarbutz'
    context = { goober: 'gutz' }

    expected_args = [JunkDrawer::NotifierError.new(message), context: context]
    expect do
      strategy.(message, **context)
    end.to invoke(:notify).on(Honeybadger).with(*expected_args)
  end

  it 'notifies honeybadger with the given error when given an error' do
    class TestError < StandardError; end
    error = TestError.new('this is a message')
    context = { goober: 'gutz' }

    expect do
      strategy.(error, **context)
    end.to invoke(:notify).on(Honeybadger).with(error, context: context)
  end
end
