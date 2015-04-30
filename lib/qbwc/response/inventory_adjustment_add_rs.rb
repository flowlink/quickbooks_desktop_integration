module QBWC
  module Response
    class InventoryAdjustmentAddRs
      attr_reader :records

      def initialize(records)
        @records = records
      end

      def handle_error(errors, config)
        errors.each do |error|
          Persistence::Object.handle_error(config,
                                           error.merge(context: 'Seting inventories'),
                                           'inventories',
                                           error[:request_id])
        end
      end

      def process(config = {})
        return { 'statuses_objects' => nil } if records.empty?

        inventories = []
        records.each do |object|
          inventories << { inventories: {
            id: object['RefNumber'],
            list_id: object['TxnID'],
            edit_sequence: object['EditSequence']
          }
                      }
        end

        Persistence::Object.update_statuses(config, inventories)
      end
    end
  end
end
