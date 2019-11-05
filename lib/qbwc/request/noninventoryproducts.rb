module QBWC
  module Request
    class Noninventoryproducts

      FIELD_MAP = {
        ManufacturerPartNumber: "manufacturer_part_number",
        IsTaxIncluded: "is_tax_included",
        ExternalGUID: "external_guid"
      }

      REF_MAP = {
        ClassRef: "class_name",
        ParentRef: "parent_name",
        UnitOfMeasureSetRef: "unit_of_measure",
        SalesTaxCodeRef: "sales_tax_code_name"
      }

      class << self
        def generate_request_insert_update(objects, params = {})
          objects.inject('') do |request, object|
            config = { connection_id: params['connection_id'] }.with_indifferent_access
            session_id = Persistence::Session.save(config, object)

            request << if object[:list_id].to_s.empty?
                         add_xml_to_send(object, params, session_id)
                       else
                         update_xml_to_send(object, params, session_id)
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
            <ItemNonInventoryQueryRq requestID="#{session_id}">
              <MaxReturned>10000</MaxReturned>
              <NameRangeFilter>
                <FromName>#{product_id}</FromName>
                <ToName>#{product_id}</ToName>
              </NameRangeFilter>
            </ItemNonInventoryQueryRq>
          XML
        end

        def add_xml_to_send(product, params, session_id)
          <<~XML
            <ItemNonInventoryAddRq requestID="#{session_id}">
               <ItemNonInventoryAdd>
                #{product_xml(product, params)}
               </ItemNonInventoryAdd>
            </ItemNonInventoryAddRq>
          XML
        end

        def update_xml_to_send(product, params, session_id)
          <<~XML
            <ItemInventoryModRq requestID="#{session_id}">
               <ItemInventoryMod>
                  <ListID>#{product['list_id']}</ListID>
                  <EditSequence>#{product['edit_sequence']}</EditSequence>
                  #{product.key?('active') ? product_only_touch_xml(product, params) : product_xml(product, params)}
               </ItemInventoryMod>
            </ItemInventoryModRq>
          XML
        end

        def product_only_touch_xml(product, _params)
          <<~XML
                  <Name>#{product['product_id']}</Name>
                  <IsActive>true</IsActive>
          XML
        end

        def product_xml(product, params)
          <<~XML
              <Name>#{product['product_id'] || product['sku']}</Name>
              <IsActive >#{product['is_active'] || true}</IsActive>
              #{add_refs(product)}
              #{add_fields(product, FIELD_MAP)}
              #{add_barcode(product)}
              #{sale_or_and_purchase(product)}

              <SalesDesc>#{product['description']}</SalesDesc>
              <SalesPrice>#{'%.2f' % product['price'].to_f}</SalesPrice>
              <PurchaseCost>#{'%.2f' % product['cost'].to_f}</PurchaseCost>
          XML
        end

        def polling_current_items_xml(params, config)
          timestamp = params
          timestamp = params['quickbooks_since'] if params['return_all']

          session_id = Persistence::Session.save(config, 'polling' => timestamp)

          time = Time.parse(timestamp).in_time_zone 'Pacific Time (US & Canada)'

          <<~XML
            <!-- polling non inventory products -->
            <ItemNonInventoryQueryRq requestID="#{session_id}">
            <MaxReturned>100</MaxReturned>
              #{query_by_date(params, time)}
            </ItemNonInventoryQueryRq>
          XML
        end

        private

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

        def sale_or_and_purchase(product)
          if product['sale_or_purchase']
            <<~XML
              <SalesOrPurchase>
                <Desc>#{product['description']}</Desc>
                <Price>#{'%.2f' % product['price'].to_f}</Price>
                <PricePercent>#{product['price_percent']}</PricePercent>
                <AccountRef><FullName>#{product['account_name'] || config['account_name']}</FullName></AccountRef>
              </SalesOrPurchase>
            XML
          else
            <<~XML
              <SalesAndPurchase>
                <SalesDesc>#{product['description']}</SalesDesc>
                <SalesPrice>#{product['description']}</SalesPrice>
                <PurchaseDesc>#{product['description']}</PurchaseDesc>
                <PurchaseCost>#{product['description']}</PurchaseCost>
                <IncomeAccountRef><FullName>#{product['account_name'] || config['account_name']}</FullName></IncomeAccountRef>
                <PurchaseTaxCodeRef><FullName>#{product['account_name'] || config['account_name']}</FullName></PurchaseTaxCodeRef>
                <ExpenseAccountRef><FullName>#{product['account_name'] || config['account_name']}</FullName></ExpenseAccountRef>
                <PrefVendorRef><FullName>#{product['account_name'] || config['account_name']}</FullName></PrefVendorRef>
              </SalesAndPurchase>
            XML
          end
        end

        def add_refs(object)
          fields = ""
          REF_MAP.each do |qbe_name, flowlink_name|
            fields += "<#{qbe_name}><FullName>#{object[flowlink_name]}</FullName></#{qbe_name}>" unless object[flowlink_name].nil?
          end

          fields
        end

        def add_fields(object, mapping)
          fields = ""
          mapping.each do |qbe_name, flowlink_name|
            fields += "<#{qbe_name}>#{object[flowlink_name]}</#{qbe_name}>\n" unless object[flowlink_name].nil?
          end

          fields
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
