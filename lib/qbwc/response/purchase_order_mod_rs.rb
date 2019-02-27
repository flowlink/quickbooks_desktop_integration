module QBWC
  module Response
    class PurchaseOrderModRs
      attr_reader :records

      def initialize(records)
        @records = records
      end

      def handle_error(errors, config)
        errors.each do |error|
          Persistence::Object.handle_error(config,
                                           error.merge(context: 'Adding purchaseorders'),
                                           'purchaseorders',
                                           error[:request_id])
        end
      end

      def process(config = {})
        purchaseorders = records.inject([]) do |purchaseorders, record|
          purchaseorders << {
            purchaseorders: {
              id: record['RefNumber'],
              list_id: record['TxnID'],
              edit_sequence: record['EditSequence']
            }
          }
        end

        Persistence::Object.update_statuses(config, purchaseorders)
      end
    end
  end
end
