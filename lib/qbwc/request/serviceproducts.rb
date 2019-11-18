module QBWC
  module Request
    class Serviceproducts

      GENERAL_MAPPING = [
        {qbe_name: "ParentRef", flowlink_name: "parent_name", is_ref: true},
        {qbe_name: "ClassRef", flowlink_name: "class_name", is_ref: true},
        {qbe_name: "UnitOfMeasureSetRef", flowlink_name: "unit_of_measure", is_ref: true},
        {qbe_name: "IsTaxIncluded", flowlink_name: "is_tax_included", is_ref: false},
        {qbe_name: "SalesTaxCodeRef", flowlink_name: "sales_tax_code_name", is_ref: true},
      ]

      SALES_OR_PURCHASE_MAP = [
        {qbe_name: "Desc", flowlink_name: "description", is_ref: false},
        {qbe_name: "Price", flowlink_name: "price", is_ref: false},
        {qbe_name: "PricePercent", flowlink_name: "price_percent", is_ref: false},
        {qbe_name: "AccountRef", flowlink_name: "account_name", is_ref: true}
      ]

      SALES_AND_PURCHASE_MAP = [
        {qbe_name: "SalesDesc", flowlink_name: "description", is_ref: false},
        {qbe_name: "SalesPrice", flowlink_name: "price", is_ref: false},
        {qbe_name: "IncomeAccountRef", flowlink_name: "income_account", is_ref: true},
        {qbe_name: "PurchaseDesc", flowlink_name: "purchase_description", is_ref: false},
        {qbe_name: "PurchaseCost", flowlink_name: "cost", is_ref: false},
        {qbe_name: "PurchaseTaxCodeRef", flowlink_name: "purchase_tax_code_name", is_ref: true},
        {qbe_name: "ExpenseAccountRef", flowlink_name: "expense_account", is_ref: true},
        {qbe_name: "PrefVendorRef", flowlink_name: "preferred_vendor_name", is_ref: true}
      ]

      EXTERNAL_GUID_MAP = [{qbe_name: "ExternalGUID", flowlink_name: "external_guid", is_ref: false}]

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

            request << search_xml(product_identifier(object), session_id)
          end
        end

        def search_xml(product_id, session_id)
          <<~XML
            <ItemServiceQueryRq requestID="#{session_id}">
              <MaxReturned>10000</MaxReturned>
              <NameRangeFilter>
                <FromName>#{product_id}</FromName>
                <ToName>#{product_id}</ToName>
              </NameRangeFilter>
            </ItemServiceQueryRq>
          XML
        end

        def add_xml_to_send(product, params, session_id, config)
          <<~XML
            <ItemServiceAddRq requestID="#{session_id}">
               <ItemServiceAdd>
                #{product_xml(product, params, config)}
               </ItemServiceAdd>
            </ItemServiceAddRq>
          XML
        end

        def update_xml_to_send(product, params, session_id, config)
          <<~XML
            <ItemServiceModRq requestID="#{session_id}">
               <ItemServiceMod>
                  <ListID>#{product['list_id']}</ListID>
                  <EditSequence>#{product['edit_sequence']}</EditSequence>
                  #{product.key?('active') ? product_only_touch_xml(product, params) : product_xml(product, params, config)}
               </ItemServiceMod>
            </ItemServiceModRq>
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
            #{add_barcode(product)}
            <IsActive >#{product['is_active'] || true}</IsActive>
            #{add_fields(product, GENERAL_MAPPING, config)}
            #{sale_or_and_purchase(product, config)}
            #{add_fields(product, EXTERNAL_GUID_MAP, config)}
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
            <!-- polling non inventory products -->
            <ItemServiceQueryRq requestID="#{session_id}">
              <MaxReturned>100</MaxReturned>
                #{query_by_date(params, time)}
            </ItemServiceQueryRq>
          XML
        end

        private

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

        def sale_or_and_purchase(product, config)
          if product['sale_or_purchase']
            <<~XML
              <SalesOrPurchase>
                #{add_fields(product, SALES_OR_PURCHASE_MAP, config)}
              </SalesOrPurchase>
            XML
          else
            <<~XML
              <SalesAndPurchase>
                #{add_fields(product, SALES_AND_PURCHASE_MAP, config)}
              </SalesAndPurchase>
            XML
          end
        end

        def add_fields(object, mapping, config)
          fields = ""
          mapping.each do |map_item|
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