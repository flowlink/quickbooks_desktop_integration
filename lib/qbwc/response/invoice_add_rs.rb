module QBWC
  module Response
    class InvoiceAddRs
      attr_reader :records

      def initialize(records)
        @records = records
      end

      def handle_error(errors, config)
        errors.each do |error|
          Persistence::Object.handle_error(
            config,
            error.merge(context: 'Adding Shipments'),
            "shipments",
            error[:request_id]
          )
        end
      end

      def process(config = {})
        return { statuses_objects: nil }.with_indifferent_access if records.empty?

        objects = records.map do |object|
          {
            shipments: {
              id: object['PONumber'],
              order_id:object['RefNumber'],
              list_id: object['TxnID'],
              edit_sequence: object['EditSequence']
            }
          }
        end

        Persistence::Object.new(config, {}).create_payments_updates_from_shipments(config, records.first['RefNumber'], records.first['TxnID'])

        Persistence::Object.update_statuses(config, objects)
      end
    end
  end
end
