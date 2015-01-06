module QBWC
  module Request
    class Inventories
      class << self
        def generate_request_insert_update(objects, params = {})
          objects.inject("") do |request, object|
            session_id = Persistence::Object.new({connection_id: params['connection_id']}.with_indifferent_access,{}).save_session(object)
            request << add_xml_to_send(object, params, session_id)
          end
        end

        def generate_request_queries(objects, params)
          # There is no query
          ''
        end

        def polling_current_items_xml(timestamp, config)
          #Get objects from a file of IDs
          objects = []
          session_id = Persistence::Object.new(config,{}).save_session({"item_inventories_ids" => objects})
          codes = objects.inject("") do |codes, object|
            codes << "<FullName>#{object['id']}</FullName>"
          end

          <<-XML
    <ItemInventoryQueryRq requestID="#{session_id}">
      #{codes}
    </ItemInventoryQueryRq>
          XML
        end


        def polling_others_items_xml(timestamp, config)
          session_id = Persistence::Object.new(config,{}).save_session({"polling" => timestamp})

          time = Time.parse(timestamp).in_time_zone "Pacific Time (US & Canada)"

          <<-XML
<ItemInventoryQueryRq requestID="#{session_id}">
 <MaxReturned>100</MaxReturned>
 <FromModifiedDate>#{time.iso8601}</FromModifiedDate>
</ItemInventoryQueryRq>

<InventoryAdjustmentQueryRq requestID="#{session_id}">
  <MaxReturned>100</MaxReturned>
  <FromModifiedDate>#{time.iso8601}</FromModifiedDate>
  <IncludeLineItems>true</IncludeLineItems>
<InventoryAdjustmentQueryRq>

<ItemReceiptQueryRq requestID="#{session_id}">
  <MaxReturned>100</MaxReturned>
  <FromModifiedDate>#{time.iso8601}</FromModifiedDate>
  <IncludeLineItems>true</IncludeLineItems>
<ItemReceiptQueryRq>

<PurchaseOrderQueryRq requestID="#{session_id}">
  <MaxReturned>100</MaxReturned>
  <FromModifiedDate>#{time.iso8601}</FromModifiedDate>
  <IncludeLineItems>true</IncludeLineItems>
<PurchaseOrderQueryRq>
          XML
        end


        # TODO BUG: http://www.productivecomputing.com/forum/index.php?topic=2559.0
        def add_xml_to_send(inventory, params, session_id)
          <<-XML
<InventoryAdjustmentAddRq requestID="#{session_id}">
   <InventoryAdjustmentAdd>
    #{inventory_xml(inventory, params)}
   </InventoryAdjustmentAdd>
</InventoryAdjustmentAddRq>
          XML
        end

        def inventory_xml(inventory, params)
          <<-XML

      <AccountRef>
        <FullName>#{params['quickbooks_income_account']}</FullName>
      </AccountRef>
      <RefNumber>#{inventory['id']}</RefNumber>
      <Memo>test adjustment</Memo>
      <InventoryAdjustmentLineAdd>
        <ItemRef>
          <FullName>#{inventory['product_id']}</FullName>
        </ItemRef>
        <ValueAdjustment>
          <NewQuantity>#{inventory['quantity'].to_f}</NewQuantity>
        </ValueAdjustment>
      </InventoryAdjustmentLineAdd>

          XML
        end
      end
    end
  end
end

