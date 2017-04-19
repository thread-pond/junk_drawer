# frozen_string_literal: true

RSpec.describe JunkDrawer::Notifier::NullStrategy, '#call' do
  let(:strategy) { described_class.new }

  class FakeHoneybadger
    def notify(error, options)
    end
  end

  before { stub_const('Honeybadger', FakeHoneybadger) }

  it 'does nothing' do
    expect do
      strategy.('foobarbutz', goober: 'gutz')
    end.not_to invoke(:notify).on(Honeybadger)
  end
end
