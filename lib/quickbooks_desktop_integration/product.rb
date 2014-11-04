module QuickbooksDesktopIntegration
  class Product
    attr_reader :result, :records

    def initialize(xml)
      xml.slice! '<?xml version="1.0" ?>'
      parser = Nori.new :strip_namespaces => true
      envelope = parser.parse xml

      response = envelope['Envelope']['Body']['receiveResponseXML']['response']
      @result = response['QBXML']['QBXMLMsgsRs']['ItemInventoryAddRs']

      products = result['ItemInventoryRet']
      @records = products.is_a?(Array) ? products : [products].compact
    end

    def mapped_records
      records.map do |record|
        {
          id: record['Name'],
          sku: record['Name'],
          product_id: record['Name'],
          description: record['FullName'],
          price: record['SalesPrice'],
          cost_price: record['AverageCost'],
          available_on: record['TimeModified'],
          income_account_id: record['IncomeAccountRef']['FullName'],
          quickbooks_id: record['ListID']
          quickbooks_version: record['EditSequence']
        }
      end
    end

    def config
      #TODO changed to yml database
      {
        'quickbooks_income_account'    => 'Inventory Asset',
        'quickbooks_cogs_account'      => 'Inventory Asset',
        'quickbooks_inventory_account' => 'Inventory Asset'
      }
    end

    def add_xml_to_send(product)
      <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<?qbxml version="13.0"?>
<QBXML>
   <QBXMLMsgsRq onError="stopOnError">
      <ItemInventoryAddRq>
         <ItemInventoryAdd>
            <Name>#{product['id']}</Name>
            <FullName>#{product['description']}</FullName>
            <IncomeAccountRef>
               <FullName>#{config['quickbooks_income_account']}</FullName>
            </IncomeAccountRef>
            <PurchaseCost>#{product['price']}</PurchaseCost>
            <COGSAccountRef>
              <FullName>#{config['quickbooks_cogs_account']}</FullName>
            </COGSAccountRef>
            <AssetAccountRef>
               <FullName>#{config['quickbooks_inventory_account']}</FullName>
            </AssetAccountRef>
            <AverageCost>#{product['cost_price']}</AverageCost>
         </ItemInventoryAdd>
      </ItemInventoryAddRq>
   </QBXMLMsgsRq>
</QBXML>
      XML
    end

    def update_xml_to_send(product)
      <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<?qbxml version="13.0"?>
<QBXML>
   <QBXMLMsgsRq onError="stopOnError">
      <ItemInventoryModRq>
         <ItemInventoryMod>
            <ListID>#{product['quickbooks_id']}</ListID>
            <EditSequence>#{product['quickbooks_version']}</EditSequence>
            <Name>#{product['id']}</Name>
            <FullName>#{product['description']}</FullName>
            <IncomeAccountRef>
               <FullName>#{config['quickbooks_income_account']}</FullName>
            </IncomeAccountRef>
            <PurchaseCost>#{product['price']}</PurchaseCost>
            <COGSAccountRef>
              <FullName>#{config['quickbooks_cogs_account']}</FullName>
            </COGSAccountRef>
            <AssetAccountRef>
               <FullName>#{config['quickbooks_inventory_account']}</FullName>
            </AssetAccountRef>
            <AverageCost>#{product['cost_price']}</AverageCost>
         </ItemInventoryMod>
      </ItemInventoryModRq>
   </QBXMLMsgsRq>
</QBXML>
      XML
    end

  end
end
