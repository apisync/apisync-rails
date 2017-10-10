class Apisync
  module Rails
    class Http
      def self.post(attrs)
        client = Apisync.new
        client.inventory_items.save(attributes: attrs)
      end
    end
  end
end
