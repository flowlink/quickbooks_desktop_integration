module QuickbooksDesktopIntegration
  class ProductQuery
    attr_reader :result, :records

    def initialize(xml)
      # File.open('/Users/pablo/spree/quickbooks_desktop_integration/spec/support/qbxml_examples/item_query_rs.xml', 'w') { |file| file.write(xml) }

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
          id: record['ListID'],
          name: record['Name'],
          description: record['FullName'],
          sku: record['Name'],
          price: record['SalesPrice'],
          cost_price: record['PurchaseCost']
          # variants
        }
      end
    end
  end
end
