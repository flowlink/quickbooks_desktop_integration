module QBWC
  module Response
    class ReceivePaymentQueryRs
      attr_reader :records

      def initialize(records)
        @records = records
      end

      def handle_error(errors, config)
        errors.each do |error|
          Persistence::Object.handle_error(config,
                                           error.merge({context: 'Querying Payments'}),
                                           "payments",
                                           error[:request_id])
        end
      end

      def process(config = {})
        return if records.empty?

        puts records.inspect

        config  = { origin: 'wombat', connection_id: config[:connection_id]  }.with_indifferent_access
        objects_updated = objects_to_update(config)

        if records.first['request_id'].start_with?('shipment')
          _, shipment_id, _ = records.first['request_id'].split('-')
          Persistence::Object.new(config, {}).update_shipments_with_payment_ids(shipment_id, objects_updated.first)
        else
          puts "[ReceivePaymentQueryRs] This should not happen, ever! #{records.inspect}"
        end

        nil
      end

      def objects_to_update(config)
        records.map do |record|
          {
            object_type: 'payment',
            object_ref: record['RefNumber'],
            list_id: record['TxnID'],
            edit_sequence: record['EditSequence'],
          }.with_indifferent_access
        end
      end


      def to_wombat
        # TODO finish the map
        records.map do |record|
          object = {
            id: record['RefNumber'],
          }

          object
        end
      end
    end
  end
end
