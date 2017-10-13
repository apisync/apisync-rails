class Apisync
  module Rails
    class Http
      def self.post(attrs, request_concurrency:, too_many_requests_attempts: nil, concurrency_lib: nil)
        headers = {}
        headers["X-Request-Concurrency"] = request_concurrency.to_s

        if ::Rails.respond_to?(:gem_version)
          rails_version = ::Rails.gem_version.to_s
        elsif Rails::VERSION.is_a?(String)
          rails_version = Rails::VERSION
        elsif Rails::VERSION::STRING
          rails_version = Rails::VERSION::STRING
        end

        headers["X-Framework"] = "Ruby on Rails #{rails_version}"
        headers["X-Client-Library"] = "apisync-rails #{Apisync::Rails::VERSION}"

        if concurrency_lib
          headers["X-Concurrency-Lib"] = concurrency_lib.to_s
        end
        if too_many_requests_attempts
          headers["X-TooManyRequests-Attempts"] = too_many_requests_attempts.to_s
        end

        client = Apisync.new
        response = client.inventory_items.save(attributes: attrs, headers: headers)

        unless response.success?
          reference_id_msg = ""
          if attributes["reference_id"].present?
            reference_id_msg = "with reference_id '#{attributes["reference_id"]}' "
          end

          ::Rails.logger.warn "[apisync] Request #{reference_id}failed: #{response.body}"
        end

        response
      end
    end
  end
end
