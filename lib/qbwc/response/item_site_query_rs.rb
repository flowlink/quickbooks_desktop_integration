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

          inventory_params['inventories']['quickbooks_force_config'] = 'true'
          params = inventory_params['inventories']

          Persistence::Settings.new(params.with_indifferent_access).setup
        end

        nil
      end

      private

      def inventories_to_flowlink
        records.map do |record|
          {
            id: full_name(record) + '-site-' + inventory_site(record),
            list_id: record['ListID'],
            created_at: record['TimeCreated'],
            updated_at: record['TimeModified'],
            edit_sequence: record['EditSequence'],
            full_name: full_name(record),
            qbe_item_type: record['ItemInventoryRef'] ? 'qbe_inventory' : 'inventory_assembly',
            inventory_item_name: record['ItemInventoryRef'] ? record['ItemInventoryRef']['FullName'] : '',
            assembly_item_name: record['ItemInventoryAssemblyRef'] ? record['ItemInventoryAssemblyRef']['FullName'] : '',
            quantity_on_hand: record['QuantityOnHand'],
            inventory_site: inventory_site(record),
            inventory_site_location: inventory_site_location(record),
            quantity_on_po: record['QuantityOnPurchaseOrders'],
            quantity_on_sales_order: record['QuantityOnSalesOrders'],
            quantity_to_be_assembled: record['QuantityToBeBuiltByPendingBuildTxns'],
            quantity_by_being_assembled: record['QuantityRequiredByPendingBuildTxns'],
            quantity_by_pending_transfer: record['QuantityOnPendingTransfers']
          }
        end
      end

      def full_name(record)
        if record['ItemInventoryRef']
            record['ItemInventoryRef']['FullName']
        else
            record['ItemInventoryAssemblyRef']['FullName']
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
