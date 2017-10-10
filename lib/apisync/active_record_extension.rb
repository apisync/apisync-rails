class Apisync
  module ActiveRecordExtension
    def self.included(klass)
      klass.extend(ClassMethods)
      klass.include(InstanceMethods)
    end

    module InstanceMethods
      attr_accessor :apisync

      private

      def start_apisync
        @apisync = Apisync::Rails::Model.new(self)
        @apisync.instance_eval(&self.class.apisync_block)
        @apisync.validate!
      end

      def save_to_apisync
        @apisync.sync
      end
    end

    module ClassMethods
      def apisync_block
        @apisync_block
      end

      def apisync(&block)
        after_initialize :start_apisync
        after_commit :save_to_apisync

        @apisync_block = block
      end
    end
  end
end

ActiveSupport.on_load(:active_record) do
  ::ActiveRecord::Base.send(:include, Apisync::ActiveRecordExtension)
end
