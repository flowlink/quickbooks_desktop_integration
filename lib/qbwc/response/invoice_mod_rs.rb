module QBWC
  module Response
    class InvoiceModRs
      attr_reader :records

      def initialize(records)
        @records = records
      end

      def handle_error(errors, config)
        errors.each do |error|
          Persistence::Object.handle_error(
            config,
            error.merge(context: 'Updating Shipments'),
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
              id: object['RefNumber'],
              order_id:object['RefNumber'],
              list_id: object['TxnID'],
              edit_sequence: object['EditSequence']
            }
          }
        end

        Persistence::Object.update_statuses(config, objects)
      end
    end
  end
end
