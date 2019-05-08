module QBWC
  module Response
    class PurchaseOrderQueryRs
      attr_reader :records

      def initialize(records)
        @records = records
      end

      def handle_error(errors, config)
        errors.each do |error|
          Persistence::Object.handle_error(config,
                                           error.merge(context: 'Querying purchase orders'),
                                           'purchaseorders',
                                           error[:request_id])
        end
      end

      def process(config = {})
        return if records.empty?

        puts "Processing purchase orders: #{records}"
        receive_configs = config[:receive] || []
        purchaseorder_params = receive_configs.find { |c| c['purchaseorders'] }

        if purchaseorder_params
          payload = { purchaseorders: purchaseorders_to_flowlink }
          config = { origin: 'quickbooks' }.merge config.reject{|k,v| k == :origin || k == "origin"}

          poll_persistence = Persistence::Polling.new(config, payload)
          poll_persistence.save_for_polling

          purchaseorder_params['purchaseorders']['quickbooks_since'] = last_time_modified
          purchaseorder_params['purchaseorders']['quickbooks_force_config'] = 'true'

          # Override configs to update timestamp so it doesn't keep geting the
          # same inventories
          params = purchaseorder_params['purchaseorders']
          Persistence::Settings.new(params.with_indifferent_access).setup
        end

        config  = config.merge(origin: 'flowlink', connection_id: config[:connection_id]).with_indifferent_access
        objects_updated = objects_to_update(config)

        nil
      end

      private

      def objects_to_update(config)
        records.map do |record|
          {
            object_type: 'purchaseorder',
            object_ref: record['RefNumber'],
            list_id: record['TxnID'],
            edit_sequence: record['EditSequence']
          }.with_indifferent_access
        end
      end

      def purchaseorders_to_flowlink
        records.map do |record|
          puts "Purchase Order from QBE: #{record}"
          {
            id: record['RefNumber'],
            transaction_id: record['TxnId'],
            is_fully_received: record['IsFullyReceived'],
            vendor: {
              name: record.dig('VendorRef','FullName'),
              external_id: record.dig('VendorRef','ListID')
            },
            date: record['Txndate'].to_s,
            total: record['TotalAmount'],
            line_items: record['PurchaseOrderLineRet'].map do |item|
              {
                product_id: item.dig('ItemRef','FullName'),
                description: item['Desc'],
                quantity: item['Quantity'],
                value: item['Amount']
              }
            end
          }.compact
        end
      end

      def last_time_modified
        time = records.sort_by { |r| r['TimeModified'] }.last['TimeModified'].to_s
        Time.parse(time).in_time_zone('Pacific Time (US & Canada)').iso8601
      end
    end
  end
end
