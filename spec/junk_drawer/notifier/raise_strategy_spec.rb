# frozen_string_literal: true

RSpec.describe JunkDrawer::Notifier::RaiseStrategy, '#call' do
  let(:strategy) { described_class.new }

  it 'raises an error with the given message and context' do
    expected_message = 'foobarbutz, context: {:goober=>"gutz"}'
    expect do
      strategy.('foobarbutz', goober: 'gutz')
    end.to raise_error(JunkDrawer::NotifierError, expected_message)
  end
end
