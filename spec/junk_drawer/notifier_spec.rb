# frozen_string_literal: true

RSpec.describe JunkDrawer::Notifier, '#call' do
  let(:notifier) { described_class.new }

  it 'calls the configured notifier with the given arguments' do
    JunkDrawer::Notifier.strategy = :raise
    strategy = JunkDrawer::Notifier::RaiseStrategy
    expect do
      notifier.('foo', 'bar', 'butts')
    end.to invoke(:call).on(strategy).with('foo', 'bar', 'butts')
    JunkDrawer::Notifier.strategy = :nil
  end
end
