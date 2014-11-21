module QBWC
  module Response
    class ItemInventoryAddRs
      attr_reader :records

      def initialize(records)
        @records = records
      end

      def handle_error(errors, config)
        errors.each do |error|
          Persistence::Object.handle_error(config,
                                           error.merge({context: 'Adding products'}),
                                           "products",
                                           error[:request_id])
        end
      end

      def process(config = {})
        return { 'statuses_objects' => nil } if records.empty?

puts " \n\n\n **** Records: #{records.inspect} \n\n"

        products = []
        records.each do |object|
          products << { :products => {
                                       :id            => object['Name'],
                                       :list_id       => object['ListID'],
                                       :edit_sequence => object['EditSequence']
                                      }
                      }
        end

        Persistence::Object.update_statuses(config, products)
      end
    end
  end
end
