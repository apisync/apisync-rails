require 'spec_helper'

RSpec.describe Apisync::Rails::Http do
  let(:payload) do
    {
    }
  end

  describe '.post' do
    context 'when request fails' do
      context 'when reference-id is defined' do
        before do
          payload["reference-id"] = "my-id"
        end

      end
    end
  end
end
