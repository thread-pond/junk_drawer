# frozen_string_literal: true

RSpec.describe JunkDrawer::BulkUpdatable, '.bulk_update' do
  context 'when prepared statements are enabled' do
    with_model :TestModel do
      table do |t|
        t.string(:secret)
        t.datetime :updated_at, null: false
      end

      model do
        extend JunkDrawer::BulkUpdatable
      end
    end

    before do
      allow(TestModel.connection).to receive(:prepared_statements).and_return(true)
    end

    after do
      ActiveRecord::Base.logger = nil
      ActiveRecord::Base.filter_attributes = []
    end

    it_behaves_like 'bulk updatable model', true

    it 'generates sql that can be filtered by filter attributes in logs' do
      models = [TestModel.create!, TestModel.create!]
      models.each_with_index do |model, index|
        model.secret = "thing_#{index}"
      end

      logger = double
      allow(logger).to receive(:debug?).and_return(true)
      allow(logger).to receive(:debug)
      ActiveRecord::Base.logger = logger
      ActiveRecord::Base.filter_attributes += [:secret]

      TestModel.bulk_update(models)

      expect(logger).not_to have_received(:debug).with(/thing_1/)
      expect(logger).to have_received(:debug).with(
        /UPDATE with_model_test_models.*"secret", "\[FILTERED\]".*"secret", "\[FILTERED\]"/,
      )
    end

    it 'names the log statement' do
      model = TestModel.create!
      model.secret = 'thing'

      logger = double
      allow(logger).to receive(:debug?).and_return(true)
      allow(logger).to receive(:debug)
      ActiveRecord::Base.logger = logger

      TestModel.bulk_update([model])

      expect(logger).to have_received(:debug).with(/TestModel Bulk Update/)
    end

    it 'splits the insert into batches based on max allowable bind params' do
      connection = TestModel.connection
      allow(connection).to receive(:bind_params_length).and_return(3)
      logger = double
      allow(logger).to receive(:debug?).and_return(true)
      allow(logger).to receive(:debug)
      ActiveRecord::Base.logger = logger

      models = [TestModel.create!, TestModel.create!]
      models.each_with_index do |model, index|
        model.secret = "thing_#{index}"
      end

      TestModel.bulk_update(models)

      expect(logger).to have_received(:debug).with(/TestModel Bulk Update/).twice
    end
  end

  context 'when prepared statements are not enabled' do
    it_behaves_like 'bulk updatable model'
  end
end
