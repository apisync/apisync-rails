require 'spec_helper'

RSpec.describe "Integration/ActiveRecord", :integration do
  class DummyProduct < ::Product
    apisync do
      attribute :ad_template_type, from: :category
      attribute :available,        from: :active?
      attribute :content_language, value: "pt-br"
      attribute :brand
      attribute :model

      custom_attribute :title,     name: :title_name
      custom_attribute :description, name: :subtitle_name
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
    it 'calls apisync' do
      stub_request(:post, "https://api.apisync.io/inventory-items")
        .with(
          body: payload.to_json,
          headers: {'Accept'=>'application/vnd.api+json', 'Content-Type'=>'application/vnd.api+json'}
        )
      subject.save
    end
  end
end