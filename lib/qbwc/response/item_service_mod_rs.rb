module QBWC
  module Response
    class ItemServiceModRs
      attr_reader :records

      def initialize(records)
        @records = records
      end

      def handle_error(errors, config)
        errors.each do |error|
          Persistence::Object.handle_error(config,
                                           error.merge(context: 'Updating Service products'),
                                           'serviceproducts',
                                           error[:request_id])
        end
      end

      def process(config = {})
        return { statuses_objects: nil }.with_indifferent_access if records.empty?

        products = []
        records.each do |object|
          products << {
            serviceproducts: {
              id: build_product_id(object),
              list_id: object['ListID'],
              edit_sequence: object['EditSequence']
            }
          }
        end

        Persistence::Object.update_statuses(config, products)
      end

      private

      def build_product_id(object)
        if object['ParentRef'].is_a?(Array)
          arr = object['ParentRef'] 
        elsif object['ParentRef'].nil?
            arr = []
        else
          arr = [object['ParentRef']]
        end
        
        arr.map { |item| item['FullName'] + ':' }.join('') + object['Name']
      end
    end
  end
end