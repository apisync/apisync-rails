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
            concurrency_lib: "Sidekiq 5.0.2",
            too_many_requests_attempts: 1
          )

        subject.perform("::Product", "1", :payload)
      end

      context "when there is a 429 response (too many requests)" do
        before do
          stub_request(:post, "https://api.apisync.io/inventory-items")
            .to_return(status: 429)
        end

        it 're-schedules the current post' do
          expect(described_class)
            .to receive(:perform_in)
            .with(
              be_between(30, 300),
              "::Product",
              "1",
              :payload,
              2
            )

          subject.perform("::Product", "1", :payload)
        end
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
