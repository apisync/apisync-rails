class Apisync
  module Rails
    module SyncModelJob
      class Sidekiq
        # include ::Sidekiq::Worker (deferred)
        #
        # Sidekiq module is included in the Extensions class. We don't do it here
        # because we don't know if Sidekiq is loaded or not. If it is not, we
        # don't want to include it in this class.

        def perform(model_name, id, attributes)
          unless defined?(::Sidekiq)
            raise ArgumentError, "Sidekiq is not defined but an ApiSync job is being spun up."
          end

          Apisync::Rails::Http.post(
            attributes,
            request_concurrency: :asynchronous,
            concurrency_lib: "Sidekiq #{::Sidekiq::VERSION}"
          )
        end
      end
    end
  end
end
