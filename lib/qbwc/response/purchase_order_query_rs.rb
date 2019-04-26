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
                                           error.merge(context: 'Querying purchase orders'),
                                           'purchaseorders',
                                           error[:request_id])
        end
      end

      def process(config = {})
        return if records.empty?

        puts "Processing purchase orders: #{records}"
        receive_configs = config[:receive] || []
        purchaseorder_params = receive_configs.find { |c| c['purchaseorders'] }

        if purchaseorder_params
          payload = { purchaseorders: purchaseorders_to_flowlink }
          config = { origin: 'quickbooks' }.merge config.reject{|k,v| k == :origin || k == "origin"}

          poll_persistence = Persistence::Polling.new(config, payload)
          poll_persistence.save_for_polling

          purchaseorder_params['purchaseorders']['quickbooks_since'] = last_time_modified
          purchaseorder_params['purchaseorders']['quickbooks_force_config'] = true

          # Override configs to update timestamp so it doesn't keep geting the
          # same inventories
          params = purchaseorder_params['purchaseorders']
          Persistence::Settings.new(params.with_indifferent_access).setup
        end

        config  = config.merge(origin: 'flowlink', connection_id: config[:connection_id]).with_indifferent_access
        objects_updated = objects_to_update(config)

        nil
      end

      private

      def purchaseorders_to_flowlink
        records.map do |record|
          puts "Purchase Order from QBE: #{record}"
          {
            id: record['RefNumber'],

          }.compact
        end
      end
    end
  end
end
