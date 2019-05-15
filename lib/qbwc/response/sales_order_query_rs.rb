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
                                           error.merge(context: 'Querying Orders'),
                                           'orders',
                                           error[:request_id])
        end
      end

      def process(config = {})
        return if records.empty?

        puts records.inspect

        receive_configs = config[:receive] || []
        order_params = receive_configs.find { |c| c['orders'] }

        if order_params
          payload = { orders: orders_to_flowlink }
          config = { origin: 'quickbooks' }.merge config.reject{|k,v| k == :origin || k == "origin"}

          poll_persistence = Persistence::Polling.new(config, payload)
          poll_persistence.save_for_polling

          order_params['orders']['quickbooks_since'] = last_time_modified
          order_params['orders']['quickbooks_force_config'] = 'true'

          # Override configs to update timestamp so it doesn't keep geting the
          # same inventories
          params = order_params['orders']
          Persistence::Settings.new(params.with_indifferent_access).setup
        end

        config  = config.merge(origin: 'flowlink', connection_id: config[:connection_id]).with_indifferent_access
        objects_updated = objects_to_update(config)

        if records.first['request_id'].start_with?('shipment')
          _, shipment_id, _ = records.first['request_id'].split('-')
          Persistence::Object.new(config, {}).update_shipments_with_qb_ids(shipment_id, objects_updated.first)
        else
          # We only need to update files when is not shipments order
          Persistence::Object.new(config, {}).update_objects_with_query_results(objects_updated)
        end

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
          }.with_indifferent_access
        end
      end

      def last_time_modified
        time = records.sort_by { |r| r['TimeModified'] }.last['TimeModified'].to_s
        Time.parse(time).in_time_zone('Pacific Time (US & Canada)').iso8601
      end

      def build_extra_data(config, record)
        hash_items = build_hash_items(record)
        object_source = Persistence::Session.load(config, record['request_id'])

        mapped_lines = object_source['line_items'].to_a.map do |item|
          item['txn_line_id'] = hash_items[item['product_id'].downcase]
          item['txn_id']      = record['TxnID']
          item
        end

        mapped_adjustments = object_source['adjustments'].to_a.map do |item|
          item['txn_line_id'] = hash_items[QBWC::Request::Adjustments.adjustment_product_from_qb(item['name'].downcase, config).to_s.downcase]
          item['txn_id']      = record['TxnID']
          item
        end

        {
          'line_items' => mapped_lines,
          'adjustments' => mapped_adjustments
        }
      end

      def build_hash_items(record)
        hash = {}

        # Sometimes is an array, sometimes is not :-/
        record['SalesOrderLineRet'] = [record['SalesOrderLineRet']] unless record['SalesOrderLineRet'].is_a? Array

        record['SalesOrderLineRet'].to_a.each do |item|
          hash[item['ItemRef']['FullName'].downcase] = item['TxnLineID']
        end
        hash
      end

      def orders_to_flowlink
        records.map do |record|
          puts "sales order from qbe: #{record}"
          
          {
            id: record['RefNumber']
          }
        end
      end
    end
  end
end
