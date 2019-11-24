module QBWC
  module Request
    # We will not remove this class, because the customer probably will change their mind and we will start to use again
    class Adjustments

      GENERAL_MAPPING = [
        {qbe_name: "IsActive", flowlink_name: "is_active", is_ref: false},
        {qbe_name: "ClassRef", flowlink_name: "class_name", is_ref: true},
        {qbe_name: "ParentRef", flowlink_name: "parent_name", is_ref: true},
        {qbe_name: "IsTaxIncluded", flowlink_name: "is_tax_included", is_ref: false},
        {qbe_name: "SalesTaxCodeRef", flowlink_name: "sales_tax_code_name", is_ref: true},
      ]

      SALES_OR_PURCHASE_MAP = [
        {qbe_name: "Desc", flowlink_name: "description", is_ref: false},
        {qbe_name: "Price", flowlink_name: "price", is_ref: false},
        {qbe_name: "PricePercent", flowlink_name: "price_percent", is_ref: false},
        {qbe_name: "AccountRef", flowlink_name: "account_name", is_ref: true},
        {qbe_name: "ApplyAccountRefToExistingTxns", flowlink_name: "apply_account_ref_to_existing_txns", is_ref: false, mod_only: true}
      ]

      SALES_AND_PURCHASE_MAP = [
        {qbe_name: "SalesDesc", flowlink_name: "description", is_ref: false},
        {qbe_name: "SalesPrice", flowlink_name: "price", is_ref: false},
        {qbe_name: "IncomeAccountRef", flowlink_name: "income_account", is_ref: true},
        {qbe_name: "ApplyIncomeAccountRefToExistingTxns", flowlink_name: "apply_income_account_ref_to_existing_txns", is_ref: false, mod_only: true},
        {qbe_name: "PurchaseDesc", flowlink_name: "purchase_description", is_ref: false},
        {qbe_name: "PurchaseCost", flowlink_name: "cost", is_ref: false},
        {qbe_name: "PurchaseTaxCodeRef", flowlink_name: "purchase_tax_code_name", is_ref: true},
        {qbe_name: "ExpenseAccountRef", flowlink_name: "expense_account", is_ref: true},
        {qbe_name: "ApplyExpenseAccountRefToExistingTxns", flowlink_name: "apply_expense_account_ref_to_existing_txns", is_ref: false, mod_only: true},
        {qbe_name: "PrefVendorRef", flowlink_name: "preferred_vendor_name", is_ref: true}
      ]

      EXTERNAL_GUID_MAP = [{qbe_name: "ExternalGUID", flowlink_name: "external_guid", is_ref: false, add_only: true}]

      class << self
        def generate_request_insert_update(objects, params = {})
          objects.inject('') do |request, object|
            config = { connection_id: params['connection_id'] }.with_indifferent_access
            session_id = Persistence::Session.save(config, object)
            if object[:list_id].to_s.empty?
              request = add_xml_to_send(object, params, session_id, config)
            elsif params['is_add_adjustments_workflow'].to_s == "1"
              request = mod_xml_to_send(object, params, session_id, config)
            else
              request = ''
              objects_to_update = [{ adjustments: {
                id: object['id'],
                list_id: object['list_id'],
                edit_sequence: object['edit_sequence']
              }
                                   }]
              Persistence::Object.update_statuses(params, objects_to_update)
            end
            request
          end
        end

        def generate_request_queries(objects, params)
          objects.inject('') do |request, object|
            config = { connection_id: params['connection_id'] }.with_indifferent_access
            session_id = Persistence::Session.save(config, object)

            request << search_xml(product_identifier(object), session_id)
          end
        end

        def search_xml(adjustment_id, session_id)
          <<~XML
            <ItemOtherChargeQueryRq requestID="#{session_id}">
              <MaxReturned>100</MaxReturned>
              <NameRangeFilter>
                <FromName>#{adjustment_id}</FromName>
                <ToName>#{adjustment_id}</ToName>
              </NameRangeFilter>
            </ItemOtherChargeQueryRq>
          XML
        end

        def add_xml_to_send(adjustment, params, session_id, config)
          <<~XML
            <ItemOtherChargeAddRq requestID="#{session_id}">
               <ItemOtherChargeAdd>
                #{adjustment_xml(adjustment, params, config, false)}
               </ItemOtherChargeAdd>
            </ItemOtherChargeAddRq>
          XML
        end

        def mod_xml_to_send(adjustment, params, session_id, config)
          <<~XML
            <ItemOtherChargeModRq requestID="#{session_id}">
               <ItemOtherChargeMod>
                #{adjustment_xml(adjustment, params, config, true)}
               </ItemOtherChargeMod>
            </ItemOtherChargeModRq>
          XML
        end

        def adjustment_xml(adj, params, config, is_mod)
          adjustment = pre_mapping_logic(adj, params)

          <<~XML
            <Name>#{product_identifier(adjustment)}</Name>
            #{add_barcode(adjustment)}
            #{add_fields(adjustment, GENERAL_MAPPING, config, is_mod)}
            #{sale_or_and_purchase(adjustment, config, is_mod)}
            #{add_fields(adjustment, EXTERNAL_GUID_MAP, config, is_mod)}
          XML
        end

        def account(adjustment, params)
          if adjustment['id'].downcase.match(/discount/)
            params['quickbooks_other_charge_discount_account']
          elsif adjustment['id'].downcase.match(/shipping/)
            params['quickbooks_other_charge_shipping_account']
          else
            params['quickbooks_other_charge_tax_account']
         end
        end

        def is_adjustment_tax?(adjustment_name)
          adjustment_name.downcase.match(/tax/)
        end

        def is_adjustment_discount?(adjustment_name)
          adjustment_name.downcase.match(/discount/)
        end

        def is_adjustment_shipping_discount?(adjustment_name)
          adjustment_name.downcase.match(/shipping_discount/)
        end

        def is_adjustment_shipping?(adjustment_name)
          adjustment_name.downcase.match(/shipping/)
        end

        def adjustment_product_from_qb(adjustment_name, params, object = nil)
          if is_adjustment_shipping_discount?(adjustment_name)
            ( object && object['shipping_discount_item'] ) || params['quickbooks_shipping_discount_item']
          elsif is_adjustment_discount?(adjustment_name)
            ( object && object['discount_item'] ) || params['quickbooks_discount_item']
          elsif is_adjustment_shipping?(adjustment_name)
            ( object && object['shipping_item'] ) || params['quickbooks_shipping_item']
          elsif is_adjustment_tax?(adjustment_name)
            ( object && object['tax_item'] ) || params['quickbooks_tax_item']
         end
        end

        def pre_mapping_logic(initial_object, params)
          object = initial_object

          object['is_active'] = object['is_active'] || true
          object['account_name'] = account(initial_object, params) if account(initial_object, params)
          
          object
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

        def sale_or_and_purchase(product, config, is_mod)
          map = product['sale_or_purchase'] ? SALES_OR_PURCHASE_MAP : SALES_AND_PURCHASE_MAP
          tag = "SalesAndPurchase"

          if product['sale_or_purchase'] && is_mod
            tag = "SalesOrPurchaseMod"
          elsif product['sale_or_purchase']
            tag = "SalesOrPurchase"
          elsif is_mod
            tag = "SalesAndPurchaseMod"
          end

          <<~XML
            <"#{tag}">
              #{add_fields(product, map, config, is_mod)}
            </"#{tag}">
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
