require 'nori'

require 'qbwc/response/ItemInventoryAddRs'
require 'qbwc/response/ItemInventoryModRs'
require 'qbwc/response/ItemInventoryQueryRs'
require 'qbwc/response/CustomerQueryRs'
require 'qbwc/response/CustomerAddRs'

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

          class_name.new(value.map(&:values).flatten.select { |value| value.is_a?(Hash) }).process(config)
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
