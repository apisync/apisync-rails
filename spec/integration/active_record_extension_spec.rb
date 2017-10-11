require 'spec_helper'

RSpec.describe "Integration/ActiveRecord", :integration do
  class DummyProduct < ::Product
    apisync do
      sync_if :should_sync

      attribute :ad_template_type, from: :category
      attribute :available,        from: :active?
      attribute :content_language, value: "pt-br"
      attribute :brand
      attribute :model

      custom_attribute :title,     name: :title_name
      custom_attribute :description, name: :subtitle_name
    end

    private

    def should_sync
    end

    def title_name
      "My title attr name"
    end

    def subtitle_name
      "My subtitle attr name"
    end
  end

  let(:uuid) { SecureRandom.uuid }
  let(:payload) do
    {
      data: {
        attributes: {
          ad_template_type: 'Eletronics',
          available:        true,
          content_language: "pt-br",
          brand:            "Apple",
          model:            "iPad Pro 10\"",
          custom_attributes: [{
            name:       "My title attr name",
            identifier: "title",
            value:      "iPad Pro"
          }, {
            name:       "My subtitle attr name",
            identifier: "description",
            value:      "iPad Pro for professionals"
          }],
          reference_id: uuid
        },
        type: 'inventory-items'
      }.deep_stringify_keys.deep_transform_keys!(&:dasherize)
    }
  end

  subject do
    DummyProduct.new(
      id:             uuid,
      title:          'iPad Pro',
      description:    'iPad Pro for professionals',
      category:       'Eletronics',
      active:         true,
      brand:          'Apple',
      model:          'iPad Pro 10"',
      permalink:      'https://mywebsite.com/ipad-pro',
      price_in_cents: 99900
    )
  end

  describe "#save" do
    context 'when sync_if is true' do
      before do
        stub_const("::Rails::VERSION::STRING", "5.0.0")

        allow_any_instance_of(::DummyProduct)
          .to receive(:should_sync)
          .and_return(true)
      end

      context 'when no queueing system is found' do
        it 'calls apisync directly' do
          stub_request(:post, "https://api.apisync.io/inventory-items")
            .with(
              body: payload.to_json,
              headers: {
                'Accept'                => 'application/vnd.api+json',
                'Content-Type'          => 'application/vnd.api+json',
                'Authorization'         => 'ApiToken random-key',
                'X-Client-Library'      => "apisync-rails #{Apisync::Rails::VERSION}",
                'X-Request-Concurrency' => 'synchronous',
                'X-Framework'           => 'Ruby on Rails 5.0.0',
              }
            )
          subject.save
        end
      end

      context 'when Sidekiq is defined' do
        before do
          stub_const("::Sidekiq", Class.new)
          stub_const("::Sidekiq::Worker", Module.new)
          stub_const("::Sidekiq::VERSION", "5.0.2")
          allow(Apisync::Rails::SyncModelJob::Sidekiq)
            .to receive(:perform_async) do |model_name, id, attrs|
              Apisync::Rails::SyncModelJob::Sidekiq
                .new
                .perform(model_name, id, attrs)
          end
        end

        it 'calls Sidekiq job' do
          stub_request(:post, "https://api.apisync.io/inventory-items")
            .with(
              body: payload.to_json,
              headers: {
                'Accept'                => 'application/vnd.api+json',
                'Content-Type'          => 'application/vnd.api+json',
                'Authorization'         => 'ApiToken random-key',
                'X-Client-Library'      => "apisync-rails #{Apisync::Rails::VERSION}",
                'X-Request-Concurrency' => 'asynchronous',
                'X-Framework'           => 'Ruby on Rails 5.0.0',
                'X-Concurrency-Lib'     => 'Sidekiq 5.0.2',
                'X-TooManyRequests-Attempts' => '1'
              }
            )
          subject.save
        end
      end
    end

    context 'when sync_if is false' do
      before do
        allow_any_instance_of(::DummyProduct)
          .to receive(:should_sync)
          .and_return(false)
      end

      it 'calls apisync' do
        subject.save
      end
    end
  end
end
