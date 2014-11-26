module QBWC
  module Request
    class Inventories
      class << self
        def generate_request_insert_update(objects, params = {})
          objects.inject('') do |request, object|
            request << (object[:list_id].to_s.empty?? add_xml_to_send(object, params) : update_xml_to_send(object, params))
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

        def polling_xml(timestamp, config)
          session_id = Persistence::Object.new(config,{}).save_session({"polling" => timestamp})

          time = Time.parse(timestamp).in_time_zone "Pacific Time (US & Canada)"

          <<-XML
<ItemInventoryQueryRq requestID="#{session_id}">
 <MaxReturned>100</MaxReturned>
  <FromModifiedDate>#{time.iso8601}</FromModifiedDate>
  <!-- <IncludeRetElement>Name</IncludeRetElement> -->
</ItemInventoryQueryRq>
          XML
        end

        private

        def add_xml_to_send(object, params)
          <<-XML
<ItemInventoryAddRq requestID="SXRlbUludmVudG9yeUFkZHwxNTA=" >
  <ItemInventoryAdd>
    <Name>#{object['id']}</Name>
    <IncomeAccountRef>
       <FullName>#{params['quickbooks_income_account']}</FullName>
    </IncomeAccountRef>
    <COGSAccountRef>
       <FullName>#{params['quickbooks_cogs_account']}</FullName>
    </COGSAccountRef>
    <AssetAccountRef>
       <FullName>#{params['quickbooks_inventory_account']}</FullName>
    </AssetAccountRef>
  </ItemInventoryAdd>
</ItemInventoryAddRq>
          XML
        end

        def update_xml_to_send(object, params)
          <<-XML
<ItemInventoryModRq>
   <ItemInventoryMod>
      <ListID>IDTYPE</ListID> <!-- required -->
      <EditSequence>STRTYPE</EditSequence> <!-- required -->
      <Name>#{object['id']}</Name>
      <QuantityOnHand>#{object['quantity']}</QuantityOnHand>
      <IncomeAccountRef>
         <FullName>#{params['quickbooks_income_account']}</FullName>
      </IncomeAccountRef>
      <COGSAccountRef>
        <FullName>#{params['quickbooks_cogs_account']}</FullName>
      </COGSAccountRef>
      <AssetAccountRef>
         <FullName>#{params['quickbooks_inventory_account']}</FullName>
      </AssetAccountRef>
   </ItemInventoryMod>
</ItemInventoryModRq>
          XML
        end
      end
    end
  end
end
