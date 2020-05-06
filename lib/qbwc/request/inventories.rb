module QBWC
  module Request
    class Inventories
      class << self
        def generate_request_insert_update(objects, params = {})
          objects.inject('') do |request, object|
            config = { connection_id: params['connection_id'] }.with_indifferent_access
            session_id = Persistence::Session.save(config, object)

            request << add_xml_to_send(object, params, session_id)
          end
        end

        def generate_request_queries(_objects, _params)
          # There is no query
          ''
        end

        def polling_current_items_xml(_timestamp, config)
          query_later = Persistence::Polling.new({ origin: 'quickbooks' }.merge(config), inventories: {})
                        .process_waiting_query_later_ids

          return '' if query_later.empty?

          objects = query_later.inject([]) { |all_items, obj| all_items << obj['inventories'] }.flatten
          config = { origin: 'flowlink' }.merge(config)
          session_id = Persistence::Session.save(config, 'item_inventories_ids' => objects)

          codes = objects.inject('') do |codes, object|
            codes << "<FullName>#{object['id']}</FullName>"
          end

          return '' if codes.to_s.empty?

          <<~XML
    <ItemInventoryQueryRq requestID="#{session_id}">
      #{codes}
    </ItemInventoryQueryRq>
          XML
        end

        def polling_others_items_xml(timestamp, config)
          session_id = Persistence::Session.save(config, 'polling' => timestamp)

          inventory_params = Persistence::Settings.new(config)
                             .settings('get_').find { |setting| setting.keys.first == 'inventories' }

          inventory_params['inventories']['quickbooks_since'] = Time.now.in_time_zone('Pacific Time (US & Canada)').iso8601
          inventory_params['inventories']['quickbooks_force_config'] = 'true'
          Persistence::Settings.new(inventory_params['inventories'].with_indifferent_access).setup

          time = Time.parse(timestamp).in_time_zone 'Pacific Time (US & Canada)'

          <<~XML

            <!-- begin polling inventories -->
            <ItemInventoryQueryRq requestID="#{session_id}">
            <MaxReturned>10000</MaxReturned>
            </ItemInventoryQueryRq>

            <ItemInventoryAssemblyQueryRq requestID="#{session_id}">
              <MaxReturned>10000</MaxReturned>
            </ItemInventoryAssemblyQueryRq>

            <PurchaseOrderQueryRq requestID="#{session_id}">
              <MaxReturned>10000</MaxReturned>
              <ModifiedDateRangeFilter>
                <FromModifiedDate>#{time.iso8601}</FromModifiedDate>
              </ModifiedDateRangeFilter>
              <IncludeLineItems>true</IncludeLineItems>
            </PurchaseOrderQueryRq>

            <InventoryAdjustmentQueryRq requestID="#{session_id}">
              <MaxReturned>10000</MaxReturned>
              <ModifiedDateRangeFilter>
                <FromModifiedDate>#{time.iso8601}</FromModifiedDate>
              </ModifiedDateRangeFilter>
              <IncludeLineItems>true</IncludeLineItems>
            </InventoryAdjustmentQueryRq>

            <ItemReceiptQueryRq requestID="#{session_id}">
              <MaxReturned>10000</MaxReturned>
              <ModifiedDateRangeFilter>
                <FromModifiedDate>#{time.iso8601}</FromModifiedDate>
              </ModifiedDateRangeFilter>
              <IncludeLineItems>true</IncludeLineItems>
            </ItemReceiptQueryRq>
            <!-- end polling inventories -->
          XML
        end

        # TODO BUG: http://www.productivecomputing.com/forum/index.php?topic=2559.0
        def add_xml_to_send(inventory, params, session_id)
          <<~XML
            <InventoryAdjustmentAddRq requestID="#{session_id}">
              <InventoryAdjustmentAdd>
                #{inventory_xml(inventory, params)}
              </InventoryAdjustmentAdd>
            </InventoryAdjustmentAddRq>
          XML
        end

        def inventory_xml(inventory, params)
          <<~XML
            <AccountRef>
              <FullName>#{params['quickbooks_income_account']}</FullName>
            </AccountRef>
            <RefNumber>#{inventory['id']}</RefNumber>
            #{inventory_site(inventory, params)}
            <Memo>Inventory Adjustment</Memo>
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

        def inventory_site(inventory, params)
          return unless inventory.dig('site_name') || params.dig('site_name')
        
          <<~XML
            <InventorySiteRef>
              <FullName>#{inventory['site_name'] || params['site_name']}</FullName>
            </InventorySiteRef>
          XML
        end
      end
    end
  end
end
