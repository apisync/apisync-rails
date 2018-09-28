require 'spec_helper'

RSpec.describe Apisync::Rails::Model do
  let(:model) do
    double(
      "fake_model",
      id: "my-id",
      category: "vehicles",
      active?: true,
      brand: "Ford",
      model: "Mustang",
      title: "Mustang",
      my_subtitle: "It can be yours",
      subtitle_name: "My subtitle name",
      custom_should_sync: true,
      custom_should_not_sync: false
    )
  end

  subject { described_class.new(model) }

  describe '#sync' do
    let(:payload) do
      {
        ad_template_type: "vehicles",
        available:        true,
        content_language: "pt-br",
        brand:            "Ford",
        model:            "Mustang",
        reference_id:     "my-id",
        custom_attributes: [{
          label:      'Title',
          identifier: "title",
          value:      "Mustang"
        }, {
          label:      "Subtitle Name",
          identifier: "subtitle",
          value:      "It can be yours"
        }]
      }
    end

    before do
      subject.attribute(:available,        from: :active?)
      subject.attribute(:content_language, value: "pt-br")
      subject.attribute(:brand)
      subject.attribute(:model)
      subject.custom_attribute(:title, identifier: 'title', label: 'Title')
      subject.custom_attribute(:subtitle, from: :my_subtitle, label: 'Subtitle Name')
    end

    context 'when all fields are valid' do
      before do
        subject.attribute(:ad_template_type, from: :category)
      end

      context 'sync_if is not defined' do
        it 'sends attributes to apisync correctly' do
          expect(Apisync::Rails::Http)
            .to receive(:post)
            .with(payload, request_concurrency: :synchronous)

          subject.sync
        end
      end

      context 'when Sidekiq is defined' do
        before do
          stub_const("::Sidekiq", Class.new)
          stub_const("::Sidekiq::Worker", Module.new)
          stub_const("::Apisync::Rails::SyncModelJob::Sidekiq", Class.new)
        end

        it 'schedules a Sidekiq job' do
          expect(Apisync::Rails::SyncModelJob::Sidekiq)
            .to receive(:perform_async)
            .with("RSpec::Mocks::Double", "my-id", payload)

          subject.sync
        end
      end

      context 'when sync_if references a method returning true' do
        before do
          subject.sync_if(:custom_should_sync)
        end

        it 'syncs' do
          expect(Apisync::Rails::Http).to receive(:post)
          subject.sync
        end
      end

      context 'when sync_if references a method returning false' do
        before do
          subject.sync_if(:custom_should_not_sync)
        end

        it 'does not sync' do
          expect(Apisync::Rails::Http).to_not receive(:post)
          subject.sync
        end
      end
    end

    context 'when some required fields are missing' do
      it 'raises an error' do
        expect { subject.sync }.to raise_error described_class::MissingAttribute
      end
    end
  end
end
