class Apisync
  module Rails
    class Http
      def self.post(attrs, request_concurrency:, concurrency_lib: nil)
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

        client = Apisync.new
        client.inventory_items.save(attributes: attrs, headers: headers)
      end
    end
  end
end
