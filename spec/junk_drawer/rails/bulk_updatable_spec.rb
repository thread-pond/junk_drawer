# frozen_string_literal: true

RSpec.describe JunkDrawer::BulkUpdatable, '.bulk_update' do
  DATA_TYPES = %i[
    string
    boolean
    hstore
    datetime
    jsonb
  ].freeze

  with_model :BulkUpdatableModel do
    table do |t|
      DATA_TYPES.each do |data_type|
        t.public_send(data_type, "#{data_type}_value")
      end

      t.datetime :updated_at, null: false
    end

    model do
      extend JunkDrawer::BulkUpdatable
    end
  end

  let(:models) do
    [
      BulkUpdatableModel.create!(string_value: ''),
      BulkUpdatableModel.create!(string_value: ''),
    ]
  end

  it 'updates the attribute on all the models' do
    models.each_with_index do |model, index|
      model.string_value = "thing_#{index}"
    end

    BulkUpdatableModel.bulk_update(models)
    models.each(&:reload)

    expect(models[0].string_value).to eq 'thing_0'
    expect(models[1].string_value).to eq 'thing_1'
  end

  it 'only updates the models with changes' do
    models.first.string_value = 'changed attr!'

    expect do
      BulkUpdatableModel.bulk_update(models)
    end.to change { models.first.updated_at }
      .and not_change { models.last.updated_at }
  end

  it 'updates the updated_at on the models' do
    expect do
      models.each_with_index do |model, index|
        model.string_value = "thing_#{index}"
      end

      BulkUpdatableModel.bulk_update(models)
    end.to change { models.first.reload.updated_at }
      .and change { models.last.reload.updated_at }
  end

  it "doesn't blow up when input is empty array" do
    expect do
      BulkUpdatableModel.bulk_update([])
    end.not_to raise_error
  end

  it 'works for hstore datatypes' do
    models.each_with_index do |model, index|
      model.hstore_value = { "key_#{index}": "thing_data_#{index}" }
    end

    BulkUpdatableModel.bulk_update(models)
    models.each(&:reload)

    expect(models[0].hstore_value).to eq('key_0' => 'thing_data_0')
    expect(models[1].hstore_value).to eq('key_1' => 'thing_data_1')
  end

  it 'works for jsonb datatypes' do
    models.each_with_index do |model, index|
      model.jsonb_value = { key: index }
    end

    BulkUpdatableModel.bulk_update(models)
    models.each(&:reload)

    expect(models[0].jsonb_value).to eq('key' => 0)
    expect(models[1].jsonb_value).to eq('key' => 1)
  end

  it 'works for boolean datatypes' do
    models.first.boolean_value = true
    models.last.boolean_value = false

    BulkUpdatableModel.bulk_update(models)
    models.each(&:reload)

    expect(models.first.boolean_value).to be true
    expect(models.last.boolean_value).to be false
  end

  it 'works for datetime datatypes' do
    now = Time.zone.now.round
    before = 3.days.ago.round

    models.first.datetime_value = now
    models.last.datetime_value = before

    BulkUpdatableModel.bulk_update(models)
    models.each(&:reload)

    expect(models.first.datetime_value.round).to eq now
    expect(models.last.datetime_value.round).to eq before
  end

  it 'can bulk update multiple columns at once' do
    models.first.boolean_value = true
    models.first.string_value = 'weeehooo'
    models.last.boolean_value = false
    models.last.string_value = 'plop'

    BulkUpdatableModel.bulk_update(models)
    models.each(&:reload)

    expect(models.first.boolean_value).to be true
    expect(models.first.string_value).to eq 'weeehooo'
    expect(models.last.boolean_value).to be false
    expect(models.last.string_value).to eq 'plop'
  end
end
