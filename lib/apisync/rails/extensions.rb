class Apisync
  module Rails
    class Extensions
      def self.setup

        ActiveSupport.on_load(:active_record) do
          ::ActiveRecord::Base.send(:include, Apisync::ActiveRecordExtension)
        end

        if defined?(::Sidekiq)
          sidekiq_klass = ::Apisync::Rails::SyncModelJob::Sidekiq

          # Don't include twice the same module
          unless sidekiq_klass.included_modules.include?(::Sidekiq::Worker)
            sidekiq_klass.send(:include, ::Sidekiq::Worker)
          end
        end
      end
    end
  end
end
