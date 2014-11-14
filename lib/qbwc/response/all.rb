require 'nori'

# NOTE rename all these to regular named ruby files?
require 'qbwc/response/ItemInventoryAddRs'
require 'qbwc/response/ItemInventoryModRs'
require 'qbwc/response/ItemInventoryQueryRs'
require 'qbwc/response/CustomerQueryRs'
require 'qbwc/response/CustomerAddRs'
require 'qbwc/response/CustomerModRs'

require 'qbwc/response/sales_order_query_rs'
require 'qbwc/response/sales_order_add_rs'

module QBWC
  module Response
    class All
      attr_reader :response_xml

      def initialize(response_xml)
        @response_xml = response_xml
      end

      def process(config = {})
        response_hash.map do |key, value|

          class_name = "QBWC::Response::#{key}".constantize
          value = value.is_a?(Hash)? [value] : Array(value)

          records = value.map(&:values).flatten.select { |value| value.is_a?(Hash) }

          errors = value.map do |response|
            if response['@statusSeverity'] == 'Error'
              {
                code: response['@statusCode'],
                message: response['@statusMessage']
              }
            end
          end.compact

          instance = class_name.new(records)

          # NOTE suggested api for handling errors on a per class basis ..
          instance.handle_errors errors if instance.respond_to? :handle_errors
          instance.process(config)
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
