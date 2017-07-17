# frozen_string_literal: true

RSpec.describe JunkDrawer::BulkUpdatable, '.bulk_update' do
  with_model :BulkUpdatableModel do
    table do |t|
      t.string :thing
      t.boolean :bool_thing
      t.hstore :data_thing, default: {}, null: false
      t.datetime :some_time
      t.jsonb :data_thing, default: {}, null: false
      t.datetime :updated_at
    end

    model do
      extend JunkDrawer::BulkUpdatable
    end
  end

  let(:models) do
    [
      BulkUpdatableModel.create!(thing: ''),
      BulkUpdatableModel.create!(thing: ''),
    ]
  end

  it 'updates the attribute on all the models' do
    models.each_with_index do |model, index|
      model.thing = "thing_#{index}"
    end

    BulkUpdatableModel.bulk_update(models)
    models.each(&:reload)

    expect(models[0].thing).to eq 'thing_0'
    expect(models[1].thing).to eq 'thing_1'
  end

  it 'only updates the models with changes' do
    models.first.thing = 'changed attr!'

    expect do
      BulkUpdatableModel.bulk_update(models)
    end.to change { models.first.updated_at }
      .and not_change { models.last.updated_at }
  end

  it 'updates the updated_at on the models' do
    expect do
      models.each_with_index do |model, index|
        model.thing = "thing_#{index}"
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
      model.data_thing["key_#{index}"] = "thing_data_#{index}"
    end

    BulkUpdatableModel.bulk_update(models)
    models.each(&:reload)

    expect(models[0].data_thing).to eq('key_0' => 'thing_data_0')
    expect(models[1].data_thing).to eq('key_1' => 'thing_data_1')
  end

  it 'works for jsonb datatypes' do
    models.each_with_index do |model, index|
      model.data_thing = { key: index }
    end

    BulkUpdatableModel.bulk_update(models)
    models.each(&:reload)

    expect(models[0].data_thing).to eq('key' => 0)
    expect(models[1].data_thing).to eq('key' => 1)
  end

  it 'works for boolean datatypes' do
    models.first.bool_thing = true
    models.last.bool_thing = false

    BulkUpdatableModel.bulk_update(models)
    models.each(&:reload)

    expect(models.first.bool_thing).to be true
    expect(models.last.bool_thing).to be false
  end

  it 'works for datetime datatypes' do
    now = Time.zone.now.round
    before = 3.days.ago.round

    models.first.some_time = now
    models.last.some_time = before

    BulkUpdatableModel.bulk_update(models)
    models.each(&:reload)

    expect(models.first.some_time.round).to eq now
    expect(models.last.some_time.round).to eq before
  end

  it 'can bulk update multiple columns at once' do
    models.first.bool_thing = true
    models.first.thing = 'weeehooo'
    models.last.bool_thing = false
    models.last.thing = 'plop'

    BulkUpdatableModel.bulk_update(models)
    models.each(&:reload)

    expect(models.first.bool_thing).to be true
    expect(models.first.thing).to eq 'weeehooo'
    expect(models.last.bool_thing).to be false
    expect(models.last.thing).to eq 'plop'
  end
end
