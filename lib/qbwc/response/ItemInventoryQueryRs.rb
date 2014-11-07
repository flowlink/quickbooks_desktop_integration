module QBWC
  module Response
    class ItemInventoryQueryRs
      attr_reader :records

      def initialize(records)
        @records = records
      end

      def process
        return if records.empty?

        puts records.inspect
        puts to_wombat

        # config  = { origin: 'quickbooks', account_id: 'x123' }
        # payload = { products: to_wombat }

        # integration = Service::Base.new config, payload
        # s3_object = integration.save_to_s3

        # logger.info "File #{s3_object.key} persisted on s3"
      end

      private

      def to_wombat
        records.map do |record|
          {
            id: record['ListID'],
            name: record['Name'],
            description: record['FullName'],
            sku: record['Name'],
            price: record['SalesPrice'],
            cost_price: record['PurchaseCost']
          }
        end
      end
    end
  end
end
