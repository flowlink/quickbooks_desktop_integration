require 'nori'

require 'qbwc/response/ItemInventoryAddRs'
require 'qbwc/response/ItemInventoryQueryRs'
require 'qbwc/response/ItemQueryRs'

module QBWC
  module Response
    class All
      attr_reader :response_xml

      def initialize(response_xml)
        @response_xml = response_xml
      end

      def process
        response_hash.each do |key, value|
          class_name = "QBWC::Response::#{key}".constantize
          value = value.is_a?(Hash)? [value] : Array(value)
          class_name.new(value.map(&:values).flatten.select { |value| value.is_a?(Hash) }).process
        end
      end

      private

      def response_hash
        @response_hash ||= begin
                             response_xml = CGI.unescapeHTML(self.response_xml)

                             response_xml.slice! '<?xml version="1.0" ?>'

                             nori = Nori.new strip_namespaces: true

                             envelope = nori.parse(response_xml)

                             response = envelope['Envelope']['Body']['receiveResponseXML']['response']

                             response['QBXML']['QBXMLMsgsRs']
                           end
      end
    end
  end
end
