# frozen_string_literal: true

def now
  Time.zone.now.in_time_zone('UTC').round
end

GENERATORS = {
  bigint: ->(index) { index + 10 },
  bit: ->(index) { (index % 2).to_s },
  boolean: ->(index) { index.even? },
  date: ->(index) { now.to_date - index.days },
  datetime: ->(index) { now - index.days },
  decimal: ->(index) { index * 2.3 },
  float: ->(index) { index * 2.3 },
  hstore: ->(index) { { "foo_#{index}" => "bar_#{index}" } },
  inet: ->(index) { IPAddr.new("192.168.0.#{index}") },
  integer: ->(index) { index + 5 },
  json: ->(index) { { "boo_#{index}" => "bazzle_#{index}" } },
  jsonb: ->(index) { { "bee_#{index}" => "bizzle_#{index}" } },
  macaddr: ->(index) { "08:00:2b:01:02:0#{index}" },
  string: ->(index) { "wat_#{index}" },
  text: ->(index) { "text_#{index}" },
  time: ->(index) { (now - index.hours).change(year: 2000, month: 1, day: 1) },
  timestamp: ->(index) { now - index.days },
  uuid: ->(index) { "616f5839-731e-404d-869b-d0489438632#{index}" },
}.freeze

RSpec.shared_examples 'bulk updatable type' do |type|
  let(:getter_name) { "#{type}_value" }
  let(:setter_name) { "#{type}_value=" }
  let(:type) { type }

  def model_values(models)
    BulkUpdatableModel.where(id: models.map(&:id)).pluck(getter_name)
  end

  def generate_values(models, seed: 1)
    models.each_with_index.map do |model, index|
      value = GENERATORS.fetch(type).(index * seed)
      model.public_send(setter_name, value)
    end
  end

  it "can update records from null to value for type: #{type}" do
    values = generate_values(models)

    expect do
      BulkUpdatableModel.bulk_update(models)
    end.to change { model_values(models) }.from([nil, nil]).to(values)
  end

  it "can update records from value to new value for type: #{type}" do
    old_values = generate_values(models)
    models.each(&:save!)
    new_values = generate_values(models, seed: 2)

    expect do
      BulkUpdatableModel.bulk_update(models)
    end.to change { model_values(models) }.from(old_values).to(new_values)
  end

  it "can update records from value to null for type: #{type}" do
    old_values = generate_values(models)
    models.each(&:save!)
    models.each { |model| model.public_send(setter_name, nil) }

    expect do
      BulkUpdatableModel.bulk_update(models)
    end.to change { model_values(models) }.from(old_values).to([nil, nil])
  end
end
