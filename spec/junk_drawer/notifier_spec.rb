# frozen_string_literal: true

RSpec.describe JunkDrawer::Notifier, '#call' do
  let(:notifier) { described_class.new }

  after { JunkDrawer::Notifier.strategy = :null }

  it 'calls the configured pre-defined notifier with the given arguments' do
    JunkDrawer::Notifier.strategy = :raise
    strategy = JunkDrawer::Notifier::RaiseStrategy
    expect { notifier.('foo', 'bar', 'butts') }
      .to invoke(:call).on(strategy).with('foo', 'bar', 'butts')
  end

  it 'calls the configured callable notifier with the given arguments' do
    fake_notifier = ->(thing_1, thing_2) { "#{thing_1}#{thing_2}" }
    JunkDrawer::Notifier.strategy = fake_notifier

    expect(notifier.('juan', 'deux')).to eq 'juandeux'
  end

  it 'raises an error when configured with a non-existing notifier' do
    expect { JunkDrawer::Notifier.strategy = :fake_strategy }
      .to raise_error KeyError
  end
end
