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

      SALES_OR_PURCHASE_MAP = {
        Desc: "description",
        Price: "price",
        PricePercent: "price_percent"
      }

      SALES_AND_PURCHASE_MAP = {
        SalesDesc: "description",
        SalesPrice: "price",
        PurchaseDesc: "purchase_description",
        PurchaseCost: "cost"
      }

      SALES_AND_PURCHASE_REF_MAP = {
        IncomeAccountRef: "income_account",
        PurchaseTaxCodeRef: "purchase_tax_code_name",
        ExpenseAccountRef: "expense_account",
        PrefVendorRef: "preferred_vendor_name"
      }

      class << self
        def generate_request_insert_update(objects, params = {})
          objects.inject('') do |request, object|
            config = { connection_id: params['connection_id'] }.with_indifferent_access
            session_id = Persistence::Session.save(config, object)

            puts "systum1"
            puts add_xml_to_send(object, params, session_id, config).gsub(/\s+/, "")
            puts object.to_s.gsub(/\s+/, "")
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

            request << search_xml(product_identifier, session_id)
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

        def add_xml_to_send(product, params, session_id, config)
          <<~XML
            <ItemNonInventoryAddRq requestID="#{session_id}">
               <ItemNonInventoryAdd>
                #{product_xml(product, params, config)}
               </ItemNonInventoryAdd>
            </ItemNonInventoryAddRq>
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
            <IsActive >#{product['is_active'] || true}</IsActive>
            #{add_refs(product, REF_MAP, config)}
            #{add_fields(product, FIELD_MAP)}
            #{add_barcode(product)}
            #{sale_or_and_purchase(product, config)}
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
            <ItemNonInventoryQueryRq requestID="#{session_id}">
              <MaxReturned>100</MaxReturned>
                #{query_by_date(params, time)}
            </ItemNonInventoryQueryRq>
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
                #{add_fields(product, SALES_OR_PURCHASE_MAP)}
                <AccountRef><FullName>#{product['account_name'] || config['account_name'] || config['quickbooks_account_name']}</FullName></AccountRef>
              </SalesOrPurchase>
            XML
          else
            <<~XML
              <SalesAndPurchase>
                #{add_fields(product, SALES_AND_PURCHASE_MAP)}
                #{add_refs(product, SALES_AND_PURCHASE_REF_MAP, config)}
              </SalesAndPurchase>
            XML
          end
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
            return '' if object[flowlink_name].nil?

            name = flowlink_name
            name = '%.2f' % object[flowlink_name].to_f if name == 'cost' || name == 'price'

            fields += "<#{qbe_name}>#{name}</#{qbe_name}>"
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
