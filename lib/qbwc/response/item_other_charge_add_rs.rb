module QBWC
  module Response
    class ItemOtherChargeAddRs
      attr_reader :records

      def initialize(records)
        @records = records
      end

      def handle_error(errors, config)
        errors.each do |error|
          Persistence::Object.handle_error(config,
                                           error.merge(context: 'Adding adjustments'),
                                           'adjustments',
                                           error[:request_id])
        end
      end

      def process(config = {})
        return { 'statuses_objects' => nil } if records.empty?

        products = []
        records.each do |object|
          products << { adjustments: {
            id: object['Name'],
            list_id: object['ListID'],
            edit_sequence: object['EditSequence']
          }
                      }
        end

        Persistence::Object.update_statuses(config, products)
      end
    end
  end
end
