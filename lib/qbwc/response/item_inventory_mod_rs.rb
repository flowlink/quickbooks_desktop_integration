module QBWC
  module Response
    class ItemInventoryModRs
      attr_reader :records

      def initialize(records)
        @records = records
      end

      def handle_error(errors, config)
        errors.each do |error|
          Persistence::Object.handle_error(config,
                                           error.merge(context: 'Updating products'),
                                           'products',
                                           error[:request_id])
        end
      end

      def process(config = {})
        return { 'statuses_objects' => nil } if records.empty?

        products = []
        records.each do |object|
          products << { products: {
            id: (object['ParentRef'].is_a?(Array) ? object['ParentRef'] : (object['ParentRef'].nil? ? [] : [object['ParentRef']])).map { |item| item['FullName'] + ':' }.join('') + object['Name'],
            product_id: object['Name'],
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
