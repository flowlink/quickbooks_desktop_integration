module QBWC
  module Response
    class PurchaseOrderQueryRs
      attr_reader :records

      def initialize(records)
        @records = records
      end

      def handle_error(errors, config)
        errors.each do |error|
          Persistence::Object.handle_error(config,
                                           error.merge({context: 'Querying inventory adjustments'}),
                                           "inventories",
                                           error[:request_id])
        end
      end

      def process(config = {})
        return if records.empty?

        receive_configs = config[:receive] || []
        inventory_params = receive_configs.find { |c| c['inventories'] }

        payload = { inventories: inventories_to_wombat }
        config = { origin: 'quickbooks' }.merge config

        poll_persistence = Persistence::Polling.new(config, payload)
        poll_persistence.save_for_query_later

        nil
      end

      private

      def inventories_to_wombat
        records.reject { |item| item.nil? || item['PurchaseOrderLineRet'].nil? }.map do |record|
          object ||= [] << (record['PurchaseOrderLineRet'].is_a?(Array) ?
                            record['PurchaseOrderLineRet'] :
                            [record['PurchaseOrderLineRet']]).select { |line| line.has_key?('ItemRef') }.map { |item| { id: item['ItemRef']['FullName'] } }
        end.flatten
      end
    end
  end
end
