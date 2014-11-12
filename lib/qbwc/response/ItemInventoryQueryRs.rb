module QBWC
  module Response
    class ItemInventoryQueryRs
      attr_reader :records

      def initialize(records)
        @records = records
      end

      def process(config = {})
        return if records.empty?

        # TODO Error handling

        # &lt;QBXML&gt;
        # &lt;QBXMLMsgsRs&gt;
        # &lt;ItemInventoryQueryRs statusCode="1" statusSeverity="Info" statusMessage="A query request did not find a matching object in QuickBooks" /&gt;
        # &lt;/QBXMLMsgsRs&gt;
        # &lt;/QBXML&gt;

        puts records.inspect

        # NOTE How do we know when it's a response from a single object check
        # or when it's a response from a polling query request?
        #
        # The records receive could be either from a poll flow or from a
        # add product / inventory flow.
        # 
        # Here it assumes that if one configured a /get_inventory flow it
        # won't configure a add / update inventory flow. Another approach could
        # be checking the TimeModified value and add it in case it was bigger
        # than the config[:quickbooks_since] timestamp (way too hacky not reliable)
        receive_configs = config[:receive] || []
        inventory_params = receive_configs.find { |c| c['inventory'] }

        if inventory_params
          payload = { inventories: inventories_to_wombat }
          config = { origin: 'quickbooks' }.merge config

          poll_persistence = Persistence::Object.new(config, payload)
          poll_persistence.save_for_polling

          inventory_params['inventory']['quickbooks_since'] = last_time_modified
          inventory_params['inventory']['quickbooks_force_config'] = true

          # Override configs to update timestamp so it doesn't keep geting the
          # same inventories
          params = inventory_params['inventory']
          Persistence::Settings.new(params.with_indifferent_access).setup
        end

        config = { origin: 'wombat' }.merge config
        object_persistence = Persistence::Object.new config
        object_persistence.update_objects_with_query_results(objects_to_update)

        nil
      end

      def last_time_modified
        records.sort_by { |r| r['TimeModified'] }.last['TimeModified'].utc.iso8601
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

      def inventories_to_wombat
        records.map do |record|
          object = {
            id: record['Name'],
            sku: record['Name'],
            product_id: record['Name'],
            quantity: record['QuantityOnHand']
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
