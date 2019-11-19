module QBWC
  module Request
    class Products
      
      MAPPING = [
        {qbe_name: "IsActive", flowlink_name: "is_active", is_ref: false},
        {qbe_name: "ClassRef", flowlink_name: "class_name", is_ref: true},
        {qbe_name: "ParentRef", flowlink_name: "parent_name", is_ref: true},
        {qbe_name: "ManufacturerPartNumber", flowlink_name: "manufacturer_part_number", is_ref: false},
        {qbe_name: "UnitOfMeasureSetRef", flowlink_name: "unit_of_measure", is_ref: true},
        {qbe_name: "ForceUOMChange", flowlink_name: "force_uom_change", is_ref: false, mod_only: true},
        {qbe_name: "IsTaxIncluded", flowlink_name: "is_tax_included", is_ref: false},
        {qbe_name: "SalesTaxCodeRef", flowlink_name: "sales_tax_code_name", is_ref: true},
        {qbe_name: "SalesDesc", flowlink_name: "description", is_ref: false},
        {qbe_name: "SalesPrice", flowlink_name: "price", is_ref: false},
        {qbe_name: "IncomeAccountRef", flowlink_name: "income_account", is_ref: true},
        {qbe_name: "ApplyIncomeAccountRefToExistingTxns", flowlink_name: "apply_income_account_ref_to_existing_txns", is_ref: false, mod_only: true},
        {qbe_name: "PurchaseDesc", flowlink_name: "purchase_description", is_ref: false},
        {qbe_name: "PurchaseCost", flowlink_name: "cost", is_ref: false},
        {qbe_name: "PurchaseTaxCodeRef", flowlink_name: "purchase_tax_code_name", is_ref: true},
        {qbe_name: "COGSAccountRef", flowlink_name: "cogs_account", is_ref: true},
        {qbe_name: "ApplyCOGSAccountRefToExistingTxns", flowlink_name: "apply_cogs_account_ref_to_existing_txns", is_ref: false, mod_only: true},
        {qbe_name: "PrefVendorRef", flowlink_name: "preferred_vendor_name", is_ref: true},
        {qbe_name: "AssetAccountRef", flowlink_name: "inventory_account", is_ref: true},
        {qbe_name: "ReorderPoint", flowlink_name: "reorder_point", is_ref: false},
        {qbe_name: "Max", flowlink_name: "max", is_ref: false},
        {qbe_name: "QuantityOnHand", flowlink_name: "quantity", is_ref: false, add_only: true},
        {qbe_name: "TotalValue", flowlink_name: "total_value", is_ref: false, add_only: true},
        {qbe_name: "InventoryDate", flowlink_name: "inventory_date", is_ref: false, add_only: true},
        {qbe_name: "ExternalGUID", flowlink_name: "external_guid", is_ref: false, add_only: true}
      ]

      PRODUCT_TYPES = {
        inventory: "ItemInventoryQueryRq",
        assembly: "ItemInventoryAssemblyQueryRq",
        noninventory: "ItemNonInventoryQueryRq",
        salestax: "ItemSalesTaxQueryRq",
        service: "ItemServiceQueryRq",
        discount: "ItemDiscountQueryRq"
      }

      class << self
        def generate_request_insert_update(objects, params = {})
          objects.inject('') do |request, object|
            config = { connection_id: params['connection_id'] }.with_indifferent_access
            session_id = Persistence::Session.save(config, object)

            if params['connection_id'] == "kidmademodern"
              puts "KMM - kidmademodern"
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
                #{product_xml(product, params, config, false)}
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
                  #{product.key?('active') ? product_only_touch_xml(product, params) : product_xml(product, params, config, true)}
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

        def product_xml(product, params, config, is_mod)
          <<~XML
            <Name>#{product_identifier(product)}</Name>
            #{add_barcode(product)}
            #{add_fields(product, MAPPING, config, is_mod)}
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

          if params['quickbooks_specify_products'] && params['quickbooks_specify_products'] != ""
            return build_polling_from_config_param(params, session_id, time)
          end

          <<~XML
            <ItemInventoryQueryRq requestID="#{session_id}">
              <MaxReturned>50</MaxReturned>
              #{query_by_date(params, time)}
            </ItemInventoryQueryRq>
            <ItemInventoryAssemblyQueryRq requestID="#{session_id}">
              <MaxReturned>50</MaxReturned>
              #{query_by_date(params, time)}
            </ItemInventoryAssemblyQueryRq>
            <ItemNonInventoryQueryRq requestID="#{session_id}">
              <MaxReturned>50</MaxReturned>
              #{query_by_date(params, time)}
            </ItemNonInventoryQueryRq>
            <ItemSalesTaxQueryRq requestID="#{session_id}">
              <MaxReturned>50</MaxReturned>
              #{query_by_date(params, time)}
            </ItemSalesTaxQueryRq>
            <ItemServiceQueryRq requestID="#{session_id}">
              <MaxReturned>50</MaxReturned>
              #{query_by_date(params, time)}
            </ItemServiceQueryRq>
            <ItemDiscountQueryRq requestID="#{session_id}">
              <MaxReturned>50</MaxReturned>
              #{query_by_date(params, time)}
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

        def build_polling_from_config_param(params, session, time)
          JSON.parse(params['quickbooks_specify_products']).map do |value|
            next unless PRODUCT_TYPES.has_key?(value.to_sym)
            <<~XML
              <#{PRODUCT_TYPES[value.to_sym]} requestID=#{session_id}>
                <MaxReturned>50</MaxReturned>
                #{query_by_date(params, time)}
              </#{PRODUCT_TYPES[value.to_sym]}>
            XML
          end.join
        end

        def product_identifier(object)
          object['product_id'] || object['sku'] || object['id']
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

        def add_fields(object, mapping, config, is_mod)
          fields = ""
          mapping.each do |map_item|
            return "" if object[:mod_only] && object[:mod_only] != is_mod
            return "" if object[:add_only] && object[:add_only] == is_mod

            if map_item[:is_ref]
              fields += add_ref_xml(object, map_item, config)
            else
              fields += add_basic_xml(object, map_item)
            end
          end

          fields
        end

        def add_basic_xml(object, mapping)
          flowlink_field = object[mapping[:flowlink_name]]
          qbe_field_name = mapping[:qbe_name]
          float_fields = ['price', 'cost']

          return '' if flowlink_field.nil?

          flowlink_field = '%.2f' % flowlink_field.to_f if float_fields.include?(mapping[:flowlink_name])

          "<#{qbe_field_name}>#{flowlink_field}</#{qbe_field_name}>"
        end

        def add_ref_xml(object, mapping, config)
          flowlink_field = object[mapping[:flowlink_name]]
          qbe_field_name = mapping[:qbe_name]

          if flowlink_field.respond_to?(:has_key?) && flowlink_field['list_id']
            return "<#{qbe_field_name}><ListID>#{flowlink_field['list_id']}</ListID></#{qbe_field_name}>"
          end
          full_name = flowlink_field ||
                                config[mapping[:flowlink_name]] ||
                                config["quickbooks_#{mapping[:flowlink_name]}"]

          full_name.nil? ? "" : "<#{qbe_field_name}><FullName>#{full_name}</FullName></#{qbe_field_name}>"
        end

      end
    end
  end
end

