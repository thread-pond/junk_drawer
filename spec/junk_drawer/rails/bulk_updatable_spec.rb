# frozen_string_literal: true

RSpec.describe JunkDrawer::BulkUpdatable, '.bulk_update' do
  DATA_TYPES = %i[
    bigint
    bit
    boolean
    date
    datetime
    decimal
    float
    hstore
    inet
    integer
    json
    jsonb
    macaddr
    string
    text
    time
    timestamp
    uuid
  ].freeze

  ARRAY_TYPES = %i[
    integer
    string
    text
  ].freeze

  ## Types we're missing:

  ### not supported by ActiveRecord
  # char
  # real
  # smallint
  # timestampz
  # varchar

  ### probably not important
  # box
  # interval
  # line
  # lseg
  # money
  # path
  # point
  # polygon
  # range

  with_model :BulkUpdatableModel do
    table do |t|
      DATA_TYPES.each do |data_type|
        t.public_send(data_type, "#{data_type}_value")
      end

      ARRAY_TYPES.each do |data_type|
        t.public_send(data_type, "#{data_type}_array_value", array: true)
      end

      t.datetime :updated_at, null: false
    end

    model do
      extend JunkDrawer::BulkUpdatable
    end
  end

  let(:models) { [BulkUpdatableModel.create!, BulkUpdatableModel.create!] }

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

  DATA_TYPES.each do |type|
    it_behaves_like 'bulk updatable type', type
  end

  ARRAY_TYPES.each do |type|
    it_behaves_like 'bulk updatable type', "#{type}_array".to_sym
  end
end
