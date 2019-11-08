module QBWC
  module Request
    class Products

      REF_MAP = {
        ClassRef: "class_name",
        ParentRef: "parent_name",
        UnitOfMeasureSetRef: "unit_of_measure",
        SalesTaxCodeRef: "sales_tax_code_name",
        IncomeAccountRef: "income_account",
        PurchaseTaxCodeRef: "purchase_tax_code_name",
        COGSAccountRef: "cogs_account",
        PrefVendorRef: "preferred_vendor_name",
        AssetAccountRef: "inventory_account"
      }

      FIELDS_MAP = {
        ManufacturerPartNumber: "manufacturer_part_number",
        SalesDesc: "description",
        PurchaseDesc: "purchase_description",
        IsActive: "is_active",
        IsTaxIncluded: "is_tax_included",
        ReorderPoint: "reorder_point",
        Max: "max",
        QuantityOnHand: "quantity",
        TotalValue: "total_value",
        SalesPrice: "price",
        PurchaseCost: "cost",
        InventoryDate: "inventory_date",
        ExternalGUID: "external_guid"
      }

      class << self
        def generate_request_insert_update(objects, params = {})
          objects.inject('') do |request, object|
            config = { connection_id: params['connection_id'] }.with_indifferent_access
            session_id = Persistence::Session.save(config, object)
            
            if params['connection_id'] == "systum1"
              puts "systum1"
              puts add_xml_to_send(object, params, session_id, config).gsub(/\s+/, "")
            end

            request << if object[:list_id].to_s.empty?
                         add_xml_to_send(object, params, session_id, config)
                       else
                         update_xml_to_send(object, params, session_id, config)
                       end
          end
        end

        def polling_others_items_xml(_timestamp, _config)
          # nothing on this class
          ''
        end

        def generate_request_queries(objects, params)
          objects.inject('') do |request, object|
            config = { connection_id: params['connection_id'] }.with_indifferent_access
            session_id = Persistence::Session.save(config, object)

            request << search_xml(product_identifier(object), session_id)
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
            <Name>#{product_identifier(product)}</Name>
            <IsActive>true</IsActive>
          XML
        end

        def product_xml(product, params, config)
          <<~XML
            <Name>#{product_identifier(product)}</Name>
            #{add_fields(product, FIELDS_MAP)}
            #{add_refs(product, REF_MAP, config)}
            #{add_barcode(product)}
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

        private

        def product_identifier(object)
          object['product_id'] || object['sku'] || object['id']
        end

        def add_refs(object, mapping, config)
          fields = ""
          mapping.each do |qbe_name, flowlink_name|
            if object[flowlink_name].respond_to?(:has_key?) && object[flowlink_name]['list_id']
              fields += "<#{qbe_name}><ListID>#{object[flowlink_name]['list_id']}</ListID></#{qbe_name}>"
            else
              full_name = object[flowlink_name] || config[flowlink_name] || config["quickbooks_#{flowlink_name}"]
              fields += "<#{qbe_name}><FullName>#{full_name}</FullName></#{qbe_name}>" unless full_name.nil?
            end
          end

          fields
        end

        def add_fields(object, mapping)
          fields = ""
          mapping.each do |qbe_name, flowlink_name|
            next '' if object[flowlink_name].nil?

            name = object[flowlink_name]
            name = '%.2f' % name.to_f if name == 'cost' || name == 'price'

            fields += "<#{qbe_name}>#{name}</#{qbe_name}>"
          end

          fields
        end

        def add_barcode(product)
          return '' unless product['barcode_value']

          <<~XML
            <BarCode>
              <BarCodeValue>#{product['barcode_value']}</BarCodeValue>
              <AssignEvenIfUsed>#{product['assign_barcode_even_if_used'] || false}</AssignEvenIfUsed>
              <AllowOverride>#{product['allow_barcode_override'] || false}</AllowOverride>
            </BarCode>
          XML
        end

      end
    end
  end
end

