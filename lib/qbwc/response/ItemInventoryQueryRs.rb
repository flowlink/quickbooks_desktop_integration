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

        config  = { origin: 'wombat', connection_id: '54372cb069702d1f59000000'  }

        Persistence::Object.new(config, {}).update_objects_with_query_results(objects_to_update)
      end

      private

      def objects_to_update
        records.map do |record|
          {
            object_type: 'product',
            object_ref: record['Name'],
            list_id: record['ListID'],
            edit_sequence: record['EditSequence']
          }
        end
      end

      def to_wombat
        records.map do |record|
          object = {
            id: record['Name'],
            sku: record['Name'],
            product_id: record['Name'],
            quantity: record['QuantityOnHand']
          }

          # The price can be in many places :/
          if sales = record['SalesAndPurchase']
            object[:price]      = sales['SalesPrice']
            object[:cost_price] = sales['PurchaseCost']
          elsif sales = record['SalesOrPurchase']
            object[:price]      = sales['Price']
            object[:cost_price] = sales['Cost']
          else
            object[:price]      = record['SalesPrice']
            object[:cost_price] = record['PurchaseCost']
          end

          object
        end
      end
    end
  end
end
