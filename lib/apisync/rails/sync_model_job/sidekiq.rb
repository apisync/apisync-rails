class Apisync
  module Rails
    module SyncModelJob
      class Sidekiq
        # include ::Sidekiq::Worker (deferred)
        #
        # Sidekiq module is included in the Extensions class. We don't do it here
        # because we don't know if Sidekiq is loaded or not. If it is not, we
        # don't want to include it in this class.

        def perform(model_name, id, attributes, attempt = 1)
          unless defined?(::Sidekiq)
            raise ArgumentError,
              "Sidekiq is not defined but an ApiSync job is being spun up."
          end

          begin
            Apisync::Rails::Http.post(
              attributes,
              request_concurrency: :asynchronous,
              concurrency_lib: "Sidekiq #{::Sidekiq::VERSION}",
              too_many_requests_attempts: attempt.to_s
            )

          # When there are too many requests and ApiSync's API cannot take it,
          # this algorithm will push this job to be retried in the future.
          rescue Apisync::TooManyRequests
            ::Rails.logger.warn "[apisync] Too many simultaneous HTTP requests. Requests are being automatically throttled to solve this problem. Contact ApiSync support for details."

            retry_in = Random.new.rand(270) + 30 # 30 seconds - 5 minutes
            self.class.perform_in(
              retry_in,
              model_name,
              id,
              attributes,
              attempt.to_i + 1
            )
          end
        end
      end
    end
  end
end
