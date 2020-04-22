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
        puts "=" * 99
        puts 'ItemSitesQueryRs#process'
        return if records.empty?

        receive_configs = config[:receive] || []
        puts 'receive_configs'
        puts receive_configs
        inventory_params = receive_configs.find { |c| c['inventories'] }
        puts 'inventory_params'
        puts inventory_params

        puts 'records'
        puts records.inspect

        payload = { inventories: inventories_to_flowlink }
        config = { origin: 'quickbooks' }.merge config

        poll_persistence = Persistence::Polling.new(config, payload)
        poll_persistence.save_for_query_later
        puts "=" * 99
        nil
      end

      private

      def inventories_to_flowlink
        records.map do |record|
          obj = record['ItemSitesRet']
          {
            list_id: obj['ListId'],
            created_at: obj['TimeCreated'],
            updated_at: obj['TimeModified'],
            edit_sequence: obj['EditSequence'],
            full_name: obj['FullName'],
            quantity_on_hand: obj['QuantityOnHand'],
            quantity_on_po: obj['QuantityOnPurchaseOrders'],
            quantity_on_sales_order: obj['QuantityOnSalesOrders'],
            quantity_to_be_assembled: obj['QuantityToBeBuiltByPendingBuildTxns'],
            quantity_by_being_assembled: obj['QuantityRequiredByPendingBuildTxns'],
            quantity_by_pending_transfer: obj['QuantityOnPendingTransfers']
          }
        end
      end
    end
  end
end
