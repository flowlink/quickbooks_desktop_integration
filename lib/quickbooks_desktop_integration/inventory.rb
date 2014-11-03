module QuickbooksDesktopIntegration
  class Inventory
    attr_reader :result, :records

    def initialize(xml)
      xml.slice! '<?xml version="1.0" ?>'
      parser = Nori.new :strip_namespaces => true
      envelope = parser.parse xml

      response = envelope['Envelope']['Body']['receiveResponseXML']['response']
      @result = response['QBXML']['QBXMLMsgsRs']['ItemInventoryQueryRs']

      inventories = result['ItemInventoryRet']
      @records = inventories.is_a?(Array) ? inventories : [inventories].compact
    end

    def mapped_records
      records.map do |record|
        {
          id: record['Name'],
          sku: record['Name'],
          product_id: record['Name'],
          quantity: record['QuantityOnHand'],
          quickbooks: record
        }
      end
    end
  end
end
