module QBWC
  module Response
    class ItemSitesQueryRs
      attr_reader :records

      def initialize(records)
        @records = records
      end

      def handle_error(errors, config)
        errors.each do |error|
          Persistence::Object.handle_error(config,
                                           error.merge(context: 'Querying item site query'),
                                           'inventories',
                                           error[:request_id])
        end
      end

      def process(config = {})
        return if records.empty?
        puts 'ItemSitesQueryRs#process'

        receive_configs = config[:receive] || []
        inventory_params = receive_configs.find { |c| c['inventories'] }


        if inventory_params
          payload = { inventories: inventories_to_flowlink }
          config = { origin: 'quickbooks' }.merge config.reject{|k,v| k == :origin || k == "origin"}

          poll_persistence = Persistence::Polling.new(config, payload)
          poll_persistence.save_for_polling

          # inventory_params['inventories']['quickbooks_since'] = last_time_modified
          inventory_params['inventories']['quickbooks_force_config'] = 'true'

          # Override configs to update timestamp so it doesn't keep geting the
          # same inventories
          params = vendor_params['vendors']
          Persistence::Settings.new(params.with_indifferent_access).setup
        end
        config  = { origin: 'flowlink', connection_id: config[:connection_id]  }

        Persistence::Object.new(config, {}).update_objects_with_query_results(objects_to_update)

        nil
      end

      private

      def inventories_to_flowlink
        records.map do |record|
          obj = record
          {
            list_id: obj['ListId'],
            created_at: obj['TimeCreated'],
            updated_at: obj['TimeModified'],
            edit_sequence: obj['EditSequence'],
            full_name: obj['ItemInventoryRef']['FullName'],
            quantity_on_hand: obj['QuantityOnHand'],
            inventory_site: inventory_site(obj),
            inventory_site_location: inventory_site_location(obj),
            quantity_on_po: obj['QuantityOnPurchaseOrders'],
            quantity_on_sales_order: obj['QuantityOnSalesOrders'],
            quantity_to_be_assembled: obj['QuantityToBeBuiltByPendingBuildTxns'],
            quantity_by_being_assembled: obj['QuantityRequiredByPendingBuildTxns'],
            quantity_by_pending_transfer: obj['QuantityOnPendingTransfers']
          }
        end
      end

      def inventory_site(record)
        return '' if record['InventorySiteRef'] == nil
        record['InventorySiteRef']['FullName']
      end

      def inventory_site_location(record)
        return '' if record['InventorySiteLocationRef'] == nil
        record['InventorySiteLocationRef']['FullName']
      end


    end
  end
end
