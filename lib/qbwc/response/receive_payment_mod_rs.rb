module QBWC
  module Response
    class ReceivePaymentModRs
      attr_reader :records

      def initialize(records)
        @records = records
      end

      def handle_error(errors, config)
        errors.each do |error|
          Persistence::Object.handle_error(config,
                                           error.merge(context: 'Updating payments'),
                                           'payments',
                                           error[:request_id])
        end
      end

      def process(config = {})
        return { 'statuses_objects' => nil } if records.empty?

        products = []
        records.each do |record|
          products << { payments: {
            object_ref: record['RefNumber'],
            id: record['RefNumber'],
            list_id: record['TxnID'],
            edit_sequence: record['EditSequence']
          }
                      }
        end

        Persistence::Object.update_statuses(config, products)
      end
    end
  end
end
