module QBWC
  module Request
    class Products
      class << self
        def generate_request_insert_update(objects, params = {})
          objects.inject('') do |request, object|
            config = { connection_id: params['connection_id'] }.with_indifferent_access
            session_id = Persistence::Session.save(config, object)
            
            request << if object[:list_id].to_s.empty?
                         add_xml_to_send(object, params, session_id, config)
                       else
                         update_xml_to_send(object, params, session_id, config)
                       end
          end
        end

        def generate_request_queries(objects, params)
          objects.inject('') do |request, object|
            config = { connection_id: params['connection_id'] }.with_indifferent_access
            session_id = Persistence::Session.save(config, object)

            request << search_xml(object.key?('product_id') ? object['product_id'] : object['id'], session_id)
          end
        end

        def search_xml(product_id, session_id)
          <<~XML
            <ItemInventoryQueryRq requestID="#{session_id}">
              <MaxReturned>10000</MaxReturned>
              <NameRangeFilter>
                <FromName>#{product_id}</FromName>
                <ToName>#{product_id}</ToName>
              </NameRangeFilter>
            </ItemInventoryQueryRq>
          XML
        end

        def add_xml_to_send(product, params, session_id, config)
          <<~XML
            <ItemInventoryAddRq requestID="#{session_id}">
               <ItemInventoryAdd>
                #{product_xml(product, params, config)}
               </ItemInventoryAdd>
            </ItemInventoryAddRq>
          XML
        end

        def update_xml_to_send(product, params, session_id, config)
          <<~XML
            <ItemInventoryModRq requestID="#{session_id}">
                <ItemInventoryMod>
                  <ListID>#{product['list_id']}</ListID>
                  <EditSequence>#{product['edit_sequence']}</EditSequence>
                  #{product.key?('active') ? product_only_touch_xml(product, params) : product_xml(product, params, config)}
                </ItemInventoryMod>
            </ItemInventoryModRq>
          XML
        end

        def product_only_touch_xml(product, _params)
          <<~XML
            <Name>#{product['product_id'] || product['sku']}</Name>
            <IsActive>true</IsActive>
          XML
        end

        def product_xml(product, params, config)
          <<~XML
            <Name>#{product['product_id'] || product['sku']}</Name>
            <SalesDesc>#{product['description']}</SalesDesc>
            <SalesPrice>#{'%.2f' % product['price'].to_f}</SalesPrice>
            <IncomeAccountRef>
              <FullName>#{product['income_account'] || params['quickbooks_income_account']}</FullName>
            </IncomeAccountRef>
            <PurchaseCost>#{'%.2f' % product['cost'].to_f}</PurchaseCost>
            #{quantity(product)}
            #{manufacturer_part_number(product)}
            #{unit_of_measure(product)}
            <COGSAccountRef>
              <FullName>#{product['cogs_account'] || params['quickbooks_cogs_account']}</FullName>
            </COGSAccountRef>
            <AssetAccountRef>
              <FullName>#{product['inventory_account'] || params['quickbooks_inventory_account']}</FullName>
            </AssetAccountRef>
            #{inventory_date(product)}
          XML
        end

        def inventory_date(product)
          return '' unless product['quantity']
          
          date_to_use = Time.now.to_date
          date_to_use = Time.parse(product['inventory_date']).to_date if product['inventory_date']
          <<~XML
            <InventoryDate>#{date_to_use}</InventoryDate>
          XML
        end

        def quantity(product)
          return '' unless product['quantity']

          <<~XML
            <QuantityOnHand>#{product['quantity']}</QuantityOnHand>
          XML
        end

        def manufacturer_part_number(product)
          return '' unless product['manufacturer_part_number']

          <<~XML
            <ManufacturerPartNumber>#{product['manufacturer_part_number']}</ManufacturerPartNumber>
          XML
        end

        def unit_of_measure(product)
          return '' unless product['unit_of_measure']

          <<~XML
            <UnitOfMeasureSetRef>
              <FullName>#{product['unit_of_measure']}</FullName>
            </UnitOfMeasureSetRef>
          XML
        end

        def polling_others_items_xml(_timestamp, _config)
          # nothing on this class
          ''
        end

        def polling_current_items_xml(params, config)
          timestamp = params
          timestamp = params['quickbooks_since'] if params['return_all']

          session_id = Persistence::Session.save(config, 'polling' => timestamp)

          time = Time.parse(timestamp).in_time_zone 'Pacific Time (US & Canada)'

          <<~XML
            <!-- polling products -->
            <ItemInventoryQueryRq requestID="#{session_id}">
            <MaxReturned>50</MaxReturned>
              #{query_by_date(params, time)}
              <!-- <IncludeRetElement>Name</IncludeRetElement> -->
            </ItemInventoryQueryRq>
            <!-- polling assembled products -->
            <ItemInventoryAssemblyQueryRq requestID="#{session_id}">
            <MaxReturned>50</MaxReturned>
              #{query_by_date(params, time)}
              <!-- <IncludeRetElement>Name</IncludeRetElement> -->
            </ItemInventoryAssemblyQueryRq>
            <!-- polling non inventory products -->
            <ItemNonInventoryQueryRq requestID="#{session_id}">
            <MaxReturned>50</MaxReturned>
              #{query_by_date(params, time)}
              <!-- <IncludeRetElement>Name</IncludeRetElement> -->
            </ItemNonInventoryQueryRq>
            <!-- polling sales tax products -->
            <ItemSalesTaxQueryRq requestID="#{session_id}">
            <MaxReturned>50</MaxReturned>
              #{query_by_date(params, time)}
              <!-- <IncludeRetElement>Name</IncludeRetElement> -->
            </ItemSalesTaxQueryRq>
            <!-- polling service products -->
            <ItemServiceQueryRq requestID="#{session_id}">
            <MaxReturned>50</MaxReturned>
              #{query_by_date(params, time)}
              <!-- <IncludeRetElement>Name</IncludeRetElement> -->
            </ItemServiceQueryRq>
            <!-- polling discount products -->
            <ItemDiscountQueryRq requestID="#{session_id}">
            <MaxReturned>50</MaxReturned>
              #{query_by_date(params, time)}
              <!-- <IncludeRetElement>Name</IncludeRetElement> -->
            </ItemDiscountQueryRq>
          XML
        end

        def query_by_date(config, time)
          puts "Product config for polling: #{config}"
          return '' if config['return_all']

          <<~XML
            <FromModifiedDate>#{time.iso8601}</FromModifiedDate>
          XML
        end
      end
    end
  end
end
