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

        puts "\n #{records.inspect}"

        receive_configs = config[:receive] || []
        inventory_params = receive_configs.find { |c| c['inventories'] }

        payload = { inventories: inventories_to_wombat }
        config = { origin: 'quickbooks' }.merge config

        poll_persistence = Persistence::Object.new(config, payload)
        poll_persistence.save_for_query_later

        inventory_params['inventories']['quickbooks_since'] = last_time_modified
        inventory_params['inventories']['quickbooks_force_config'] = true

        # Override configs to update timestamp so it doesn't keep geting the
        # same inventories
        params = inventory_params['inventories']
        Persistence::Settings.new(params.with_indifferent_access).setup

        nil
      end

      def last_time_modified
        time = records.sort_by { |r| r['TimeModified'] }.last['TimeModified'].to_s
        Time.parse(time).in_time_zone("Pacific Time (US & Canada)").iso8601
      end

      private

      def inventories_to_wombat
        records.map do |record|
          object ||= [] << (record['PurchaseOrderLineRet'].is_a?(Array) ?
                            record['PurchaseOrderLineRet'] :
                            [record['PurchaseOrderLineRet']]).map { |item| { id: item['ItemRef']['FullName'] } }
        end.flatten
      end
    end
  end
end
