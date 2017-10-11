require 'spec_helper'

RSpec.describe Apisync::Rails::SyncModelJob::Sidekiq do
  subject { described_class.new }

  describe '#perform' do
    context 'when Sidekiq is defined' do
      before do
        stub_const("::Sidekiq", Class.new)
        stub_const("::Sidekiq::VERSION", "5.0.2")
      end

      it 'posts the attributes to apisync' do
        expect(Apisync::Rails::Http)
          .to receive(:post)
          .with(
            :payload,
            request_concurrency: :asynchronous,
            concurrency_lib: "Sidekiq 5.0.2"
          )

        subject.perform("::Product", "1", :payload)
      end
    end

    context 'when Sidekiq is not defined' do
      it 'raises error' do
        expect {
          subject.perform("::Product", "1", :payload)
        }.to raise_error ArgumentError
      end
    end
  end
end
