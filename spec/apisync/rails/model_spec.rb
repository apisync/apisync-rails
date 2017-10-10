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
      subtitle_name: "My subtitle name"
    )
  end

  subject { described_class.new(model) }

  describe '#sync' do
    before do
      subject.attribute(:available,        from: :active?)
      subject.attribute(:content_language, value: "pt-br")
      subject.attribute(:brand)
      subject.attribute(:model)
      subject.custom_attribute(:title)
      subject.custom_attribute(:subtitle, from: :my_subtitle, name: :subtitle_name)
    end

    context 'when all fields are valid' do
      before do
        subject.attribute(:ad_template_type, from: :category)
      end

      it 'sends attributes to apisync correctly' do
        expect(Apisync::Rails::Http)
          .to receive(:post)
          .with({
            ad_template_type: "vehicles",
            available:        true,
            content_language: "pt-br",
            brand:            "Ford",
            model:            "Mustang",
            reference_id:     "my-id",
            custom_attributes: [{
              name:       nil,
              identifier: "title",
              value:      "Mustang"
            }, {
              name:       "My subtitle name",
              identifier: "subtitle",
              value:      "It can be yours"
            }]
          })

        subject.sync
      end
    end

    context 'when some required fields are missing' do
      it 'raises an error' do
        expect { subject.sync }.to raise_error described_class::MissingAttribute
      end
    end
  end
end