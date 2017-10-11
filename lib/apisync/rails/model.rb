class Apisync
  module Rails
    class Model
      class MissingAttribute < StandardError; end

      REQUIRED_ATTRS = {
        available: "This is required to enable/disable your item in our database.",
        content_language: "This is required to show your item to the correct audience.",
        ad_template_type: "This is required to generate the correct ads for this item."
      }.freeze

      WARNING_ATTRS = {
        reference_id: "This is required to track your record, otherwise it will be created every time."
      }

      attr_reader :attributes

      def initialize(model)
        @model = model
        @attributes = {}
        @should_sync = true
      end

      def sync_if(method_name)
        @should_sync = @model.send(method_name.to_sym)
      end

      def attribute(attr_name, from: nil, value: nil)
        @attributes.delete(attr_name)
        @attributes[attr_name] = attr_value(attr_name, from: from, value: value)
      end

      def custom_attribute(attr_name, from: nil, value: nil, name: nil)
        @attributes[:custom_attributes] ||= []
        @attributes[:custom_attributes] << {
          name: localized_name(name),
          identifier: attr_name.to_s,
          value: attr_value(attr_name, from: from, value: value)
        }
      end

      def sync
        if sync?
          set_reference_id
          validate!
          log_warnings
          Apisync::Rails::Http.post(@attributes)
        end
      end

      def validate!
        return unless sync?

        REQUIRED_ATTRS.each do |attr, message|
          if @attributes[attr].blank?
            raise MissingAttribute, "Please specify #{attr}. #{message}"
          end
        end
      end

      def log_warnings
        WARNING_ATTRS.each do |attr, message|
          if @attributes[attr].blank?
            ::Rails.logger.warn "Please specify #{attr}. #{message}"
          end
        end
      end

      private

      def sync?
        @should_sync
      end

      def set_reference_id
        if @attributes[:reference_id].blank? && @model.id.present?
          @attributes[:reference_id] = @model.id.to_s
        end
      end

      def attr_value(attr_name, from:, value:)
        if value.blank?
          if from.present?
            value = @model.send(from)
          else
            value = @model.send(attr_name)
          end
        end
        value
      end

      def localized_name(name)
        if name.present?
          @model.send(name)
        end
      end
    end
  end
end
