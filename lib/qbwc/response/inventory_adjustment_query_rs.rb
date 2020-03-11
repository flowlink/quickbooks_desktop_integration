module QBWC
  module Response
    class InventoryAdjustmentQueryRs
      attr_reader :records

      def initialize(records)
        @records = records
      end

      def handle_error(errors, config)
        errors.each do |error|
          Persistence::Object.handle_error(config,
                                           error.merge(context: 'Querying inventory adjustments'),
                                           'inventories',
                                           error[:request_id])
        end
      end

      def process(config = {})
        puts "MARCTEST"
        puts records
        puts config
        return if records.empty?

        receive_configs = config[:receive] || []
        inventory_params = receive_configs.find { |c| c['inventories'] }
        puts inventory_params

        payload = { inventories: inventories_to_flowlink }
        config = { origin: 'quickbooks' }.merge config

        poll_persistence = Persistence::Polling.new(config, payload)
        poll_persistence.save_for_query_later
        nil
      end

      private

      def inventories_to_flowlink
        records.map do |record|
          object ||= [] << (record['InventoryAdjustmentLineRet'].is_a?(Array) ?
                            record['InventoryAdjustmentLineRet'] :
                            [record['InventoryAdjustmentLineRet']]).map { |item| { id: item['ItemRef']['FullName'] } }
        end.flatten
      end
    end
  end
end
