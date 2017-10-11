class Apisync
  module ActiveRecordExtension
    def self.included(klass)
      klass.extend(ClassMethods)
      klass.include(InstanceMethods)
    end

    module InstanceMethods
      attr_accessor :apisync

      private

      def apisync_on_after_initialize
        @apisync = Apisync::Rails::Model.new(self)
        @apisync.instance_eval(&self.class.apisync_block)
        @apisync.validate!
      end

      def apisync_on_after_commit
        @apisync.sync
      end
    end

    module ClassMethods
      def apisync_block
        @apisync_block
      end

      def apisync(&block)
        after_initialize :apisync_on_after_initialize
        after_commit :apisync_on_after_commit

        @apisync_block = block
      end
    end
  end
end
