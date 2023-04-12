# frozen_string_literal: true

RSpec.describe JunkDrawer::Notifier, '#call' do
  let(:notifier) { described_class.new }

  after { JunkDrawer::Notifier.strategy = :null }

  it 'calls the configured pre-defined notifier with the given arguments' do
    JunkDrawer::Notifier.strategy = :raise
    expected_message = 'my message, context: {:wat=>"butts"}'

    expect { notifier.('my message', wat: 'butts') }
      .to raise_error(JunkDrawer::NotifierError, expected_message)
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
