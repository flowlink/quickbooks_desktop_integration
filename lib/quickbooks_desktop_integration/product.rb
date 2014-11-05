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
          description: record['SalesDesc'],
          price: record['SalesPrice'],
          cost_price: record['PurchaseCost'],
          available_on: record['TimeModified'],
          income_account_id: record['IncomeAccountRef']['FullName']
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
    def self.search_xml(product_id)
     <<-XML
<?xml version="1.0" encoding="utf-8"?>
<?qbxml version="13.0"?>
<QBXML>
  <QBXMLMsgsRq onError="continueOnError">
    <ItemInventoryQueryRq>
      <MaxReturned>50</MaxReturned>
      <NameFilter>
        <MatchCriterion >StartsWith</MatchCriterion>
        <Name>#{product_id}</Name>
      </NameFilter>
    </ItemInventoryQueryRq>
  </QBXMLMsgsRq>
</QBXML>
      XML
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
            <SalesDesc>#{product['description']}</SalesDesc>
            <SalesPrice>#{product['price']}</SalesPrice>
            <IncomeAccountRef>
               <FullName>#{config['quickbooks_income_account']}</FullName>
            </IncomeAccountRef>
            <PurchaseCost>#{product['cost_price']}</PurchaseCost>
            <COGSAccountRef>
              <FullName>#{config['quickbooks_cogs_account']}</FullName>
            </COGSAccountRef>
            <AssetAccountRef>
               <FullName>#{config['quickbooks_inventory_account']}</FullName>
            </AssetAccountRef>
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
            <SalesDesc>#{product['description']}</SalesDesc>
            <SalesPrice>#{product['price']}</SalesPrice>
            <IncomeAccountRef>
               <FullName>#{config['quickbooks_income_account']}</FullName>
            </IncomeAccountRef>
            <PurchaseCost>#{product['cost_price']}</PurchaseCost>
            <COGSAccountRef>
              <FullName>#{config['quickbooks_cogs_account']}</FullName>
            </COGSAccountRef>
            <AssetAccountRef>
               <FullName>#{config['quickbooks_inventory_account']}</FullName>
            </AssetAccountRef>
         </ItemInventoryMod>
      </ItemInventoryModRq>
   </QBXMLMsgsRq>
</QBXML>
      XML
    end

  end
end
