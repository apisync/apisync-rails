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
        @payload = {}
        @should_sync = true
      end

      def sync_if(method_name)
        @should_sync = @model.send(method_name.to_sym)
      end

      def attribute(attr_name, from: nil, value: nil)
        @attributes.delete(attr_name)
        @attributes[attr_name] = { attr_name: attr_name, from: from, value: value }
      end

      def custom_attribute(attr_name, from: nil, value: nil, identifier: nil, label:)
        @attributes[:custom_attributes] ||= []
        @attributes[:custom_attributes] << {
          attr_name: attr_name,
          from: from,
          value: value,
          identifier: identifier,
          label: label
        }
      end

      def sync
        if sync?
          payload = generate_payload
          payload = set_reference_id(payload)
          validate!(payload)
          log_warnings(payload)

          Apisync::Rails::Extensions.setup

          if defined?(::Sidekiq)
            Apisync::Rails::SyncModelJob::Sidekiq.perform_async(
              @model.class.name,
              @model.id,
              payload
            )
          else
            Apisync::Rails::Http.post(
              payload,
              request_concurrency: :synchronous
            )
          end
        end
      end

      def validate!(payload)
        return unless sync?

        REQUIRED_ATTRS.each do |attr, message|
          if payload[attr].blank?
            raise MissingAttribute, "Please specify '#{attr}'. #{message}"
          end
        end
      end

      def log_warnings(payload)
        WARNING_ATTRS.each do |attr, message|
          if payload[attr].blank?
            ::Rails.logger.warn "Please specify '#{attr}'. #{message}"
          end
        end
      end

      private

      def generate_payload
        @payload = {}
        @attributes.each do |attr, properties|
          if attr == :custom_attributes
            custom_attrs = []
            properties.each do |custom_attr|
              from       = custom_attr[:from]
              value      = custom_attr[:value]
              attr_name  = custom_attr[:attr_name]
              label      = custom_attr[:label]
              identifier = custom_attr[:identifier]

              custom_attrs << {
                label: label || localized_name(name),
                identifier: identifier || attr_name.to_s,
                value: attr_value(attr_name, from: from, value: value)
              }
            end
            @payload[:custom_attributes] = custom_attrs
          else
            from  = properties[:from]
            value = properties[:value]
            @payload[attr] = attr_value(attr, from: from, value: value)
          end
        end

        @payload
      end

      def sync?
        @should_sync
      end

      def set_reference_id(payload)
        if payload[:reference_id].blank? && @model.id.present?
          payload[:reference_id] = @model.id.to_s
        end
        payload
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
