require 'nori'

require 'qbwc/response/customer_add_rs'
require 'qbwc/response/customer_mod_rs'
require 'qbwc/response/customer_query_rs'

require 'qbwc/response/inventory_adjustment_add_rs'
require 'qbwc/response/inventory_adjustment_query_rs'

require 'qbwc/response/invoice_add_rs'
require 'qbwc/response/invoice_mod_rs'
require 'qbwc/response/invoice_query_rs'

require 'qbwc/response/item_discount_add_rs'
require 'qbwc/response/item_discount_mod_rs'
require 'qbwc/response/item_discount_query_rs'

require 'qbwc/response/item_inventory_add_rs'
require 'qbwc/response/item_inventory_assembly_query_rs'
require 'qbwc/response/item_inventory_mod_rs'
require 'qbwc/response/item_inventory_query_rs'

require 'qbwc/response/item_non_inventory_add_rs'
require 'qbwc/response/item_non_inventory_mod_rs'
require 'qbwc/response/item_non_inventory_query_rs'

require 'qbwc/response/item_other_charge_add_rs'
require 'qbwc/response/item_other_charge_query_rs'

require 'qbwc/response/item_receipt_query_rs'

require 'qbwc/response/item_sales_tax_add_rs'
require 'qbwc/response/item_sales_tax_mod_rs'
require 'qbwc/response/item_sales_tax_query_rs'

require 'qbwc/response/item_service_add_rs'
require 'qbwc/response/item_service_mod_rs'
require 'qbwc/response/item_service_query_rs'

require 'qbwc/response/journal_entry_add_rs'
require 'qbwc/response/journal_entry_mod_rs'
require 'qbwc/response/journal_entry_query_rs'

require 'qbwc/response/purchase_order_add_rs'
require 'qbwc/response/purchase_order_mod_rs'
require 'qbwc/response/purchase_order_query_rs'

require 'qbwc/response/receive_payment_add_rs'
require 'qbwc/response/receive_payment_mod_rs'
require 'qbwc/response/receive_payment_query_rs'

require 'qbwc/response/sales_order_add_rs'
require 'qbwc/response/sales_order_mod_rs'
require 'qbwc/response/sales_order_query_rs'

require 'qbwc/response/sales_receipt_add_rs'
require 'qbwc/response/sales_receipt_mod_rs'
require 'qbwc/response/sales_receipt_query_rs'

require 'qbwc/response/txn_del_rs'

require 'qbwc/response/vendor_add_rs'
require 'qbwc/response/vendor_mod_rs'
require 'qbwc/response/vendor_query_rs'

require 'qbwc/response/item_site_query_rs'

module QBWC
  module Response
    class All
      attr_reader :response_xml

      def initialize(response_xml)
        @response_xml = response_xml
      end

      def process(config = {})
        puts({connection: config[:connection_id], message: "Processing response", response_hash: response_hash})

        response_hash.map do |key, value|

          class_name = "QBWC::Response::#{key}".constantize
          value = value.is_a?(Hash)? [value] : Array(value)
          #value.map(&:values).flatten.select { |value| value.is_a?(Hash) }

          records = value.map { |item| item.values.flatten.select { |value| value.is_a?(Hash) }
                                           .flatten
                                           .map { |sub| sub.merge({ 'request_id' => item['@requestID'] }) }
                              }.flatten

          puts({connection: config[:connection_id], message: "Processing response", records: records})

          # NOTE delete in case it's useless
          errors = value.map do |response|
            if response['@statusSeverity'] == 'Error'
              {
                code: response['@statusCode'],
                message: response['@statusMessage'],
                request_id: response['@requestID']
              }
            end
          end.compact
          response_processor = class_name.new(records)

          if errors.empty?
            response_processor.process(config)
          else
            response_processor.handle_error(errors, config)
          end
        end
      end

      private

      def response_hash
        @response_hash ||= begin
                             response_xml = CGI.unescapeHTML(self.response_xml)
                             response_xml.slice! '<?xml version="1.0" ?>'

                             nori = Nori.new strip_namespaces: true

                             envelope = nori.parse(response_xml)
                             # TODO generate notification when response is nil and message is present
                             # => {"Envelope"=>
                             # {"Body"=>
                             # {"receiveResponseXML"=>
                             # {"ticket"=>"354f40b4-b661-4472-a13f-8abf13a743c3",
                             # "response"=>nil,
                             # "hresult"=>"0x80040400",
                             # "message"=>"QuickBooks found an error when parsing the provided XML text stream.",
                             # "@xmlns"=>"http://developer.intuit.com/"}},
                             # "@xmlns:soap"=>"http://schemas.xmlsoap.org/soap/envelope/",
                             # "@xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance",
                             # "@xmlns:xsd"=>"http://www.w3.org/2001/XMLSchema"}}

                             response = envelope['Envelope']['Body']['receiveResponseXML']['response']

                             response.to_h['QBXML'].to_h['QBXMLMsgsRs'].to_h
                           end
      end
    end
  end
end
