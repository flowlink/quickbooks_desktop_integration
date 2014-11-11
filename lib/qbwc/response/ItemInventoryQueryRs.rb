module QBWC
  module Response
    class ItemInventoryQueryRs
      attr_reader :records

      def initialize(records)
        @records = records
      end

      # NOTE How do we know when it's a response from a single object check
      # or when it's a response from a polling query request?
      def process(config = {})
        return if records.empty?

        # TODO Error handling

        # &lt;QBXML&gt;
        # &lt;QBXMLMsgsRs&gt;
        # &lt;ItemInventoryQueryRs statusCode="1" statusSeverity="Info" statusMessage="A query request did not find a matching object in QuickBooks" /&gt;
        # &lt;/QBXMLMsgsRs&gt;
        # &lt;/QBXML&gt;

        puts records.inspect
        puts to_wombat

        config  = { origin: 'wombat', connection_id: config[:connection_id]  }

        Persistence::Object.new(config, {}).update_objects_with_query_results(objects_to_update)

        nil
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
