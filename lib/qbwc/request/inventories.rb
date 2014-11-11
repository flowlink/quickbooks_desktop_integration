module QBWC
  module Request
    class Inventories
      class << self
        def generate_request_insert_update(objects)
          objects.inject('') do |request, object|
            request << (object[:list_id].to_s.empty?? add_xml_to_send(object) : update_xml_to_send(object))
          end
        end

        def generate_request_queries(objects)
          objects.inject('') { |request, object| request << search_xml(object['id']) }
        end

        def search_xml(object_id)
          <<-XML
<ItemInventoryQueryRq>
  <MaxReturned>50</MaxReturned>
  <NameFilter>
    <MatchCriterion>StartsWith</MatchCriterion>
    <Name>#{object_id}</Name>
  </NameFilter>
</ItemInventoryQueryRq>
          XML
        end

        private

        def config
          # TODO changed to yml database
          {
            'quickbooks_income_account'    => 'Inventory Asset',
            'quickbooks_cogs_account'      => 'Inventory Asset',
            'quickbooks_inventory_account' => 'Inventory Asset'
          }
        end

        def add_xml_to_send(object)
          <<-XML
<ItemInventoryAddRq requestID="SXRlbUludmVudG9yeUFkZHwxNTA=" >
  <ItemInventoryAdd>
    <Name>#{object['id']}</Name>
    <IncomeAccountRef>
       <FullName>#{config['quickbooks_income_account']}</FullName>
    </IncomeAccountRef>
    <COGSAccountRef>
       <FullName>#{config['quickbooks_cogs_account']}</FullName>
    </COGSAccountRef>
    <AssetAccountRef>
       <FullName>#{config['quickbooks_inventory_account']}</FullName>
    </AssetAccountRef>
  </ItemInventoryAdd>
</ItemInventoryAddRq>
          XML
        end

        def update_xml_to_send(object)
          <<-XML
<ItemInventoryModRq>
   <ItemInventoryMod>
      <ListID>IDTYPE</ListID> <!-- required -->
      <EditSequence>STRTYPE</EditSequence> <!-- required -->
      <Name>#{object['id']}</Name>
      <QuantityOnHand>#{object['quantity']}</QuantityOnHand>
      <IncomeAccountRef>
         <FullName>#{config['quickbooks_income_account']}</FullName>
      </IncomeAccountRef>
      <COGSAccountRef>
        <FullName>#{config['quickbooks_cogs_account']}</FullName>
      </COGSAccountRef>
      <AssetAccountRef>
         <FullName>#{config['quickbooks_inventory_account']}</FullName>
      </AssetAccountRef>
   </ItemInventoryMod>
</ItemInventoryModRq>
          XML
        end

        def polling_xml
          <<-XML
<?xml version="1.0" ?>
<?qbxml version="5.0" ?>
<QBXML>
  <QBXMLMsgsRq onError="continueOnError">
    <ItemInventoryQueryRq requestID="1">
      <MaxReturned>100</MaxReturned>
      <FromModifiedDate>#{10.minutes.ago.utc.xmlschema.split('Z').first}</FromModifiedDate>
      <!-- <IncludeRetElement>Name</IncludeRetElement> -->
    </ItemInventoryQueryRq>
  </QBXMLMsgsRq>
</QBXML>
          XML
        end
      end
    end
  end
end
