module QBWC
  module Response
    class SalesOrderQueryRs
      attr_reader :records

      def initialize(records)
        @records = records
      end

      def handle_error(errors, config)
        errors.each do |error|
          Persistence::Object.handle_error(config,
                                           error.merge({context: 'Querying Orders'}),
                                           "orders",
                                           error[:request_id])
        end
      end

      def process(config = {})
        return if records.empty?

        puts records.inspect

        config  = { origin: 'wombat', connection_id: config[:connection_id]  }.with_indifferent_access
        Persistence::Object.new(config, {}).update_objects_with_query_results(objects_to_update(config))

        nil
      end

      def objects_to_update(config)
        records.map do |record|
          {
            object_type: 'order',
            object_ref: record['RefNumber'],
            list_id: record['TxnID'],
            edit_sequence: record['EditSequence'],
            extra_data: build_extra_data(config, record)
          }
        end
      end

      def build_extra_data(config, record)
        hash_items = build_hash_items(record)
        object_source = Persistence::Object.new(config, {}).load_session(record['request_id'])
        { 'line_items' => object_source['line_items'].
                           map{|item| item['txn_line_id'] = hash_items[item['product_id']]; item } }
      end

      def build_hash_items(record)
        hash = {}

        # Sometimes is an array, sometimes is not :-/
        record['SalesOrderLineRet'] = [record['SalesOrderLineRet']] unless record['SalesOrderLineRet'].is_a? Array

        record['SalesOrderLineRet'].to_a.each do |item|
          hash[item['ItemRef']['FullName']] = item['TxnLineID']
        end
        hash
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
