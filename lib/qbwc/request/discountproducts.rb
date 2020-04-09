module QBWC
  module Request
    class Discountproducts

      GENERAL_MAPPING = [
        {qbe_name: "ClassRef", flowlink_name: "class_name", is_ref: true},
        {qbe_name: "ParentRef", flowlink_name: "parent_name", is_ref: true},
        {qbe_name: "ItemDesc", flowlink_name: "description", is_ref: false},
        {qbe_name: "SalesTaxCodeRef", flowlink_name: "sales_tax_code_name", is_ref: true},
        {qbe_name: "DiscountRate", flowlink_name: "discount_rate", is_ref: false},
        {qbe_name: "DiscountRatePercent", flowlink_name: "discount_rate_percent", is_ref: false},
        {qbe_name: "AccountRef", flowlink_name: "account_name", is_ref: true},
        {qbe_name: "ApplyAccountRefToExistingTxns", flowlink_name: "apply_account_ref_to_existing_txns", is_ref: false, mod_only: true},
        {qbe_name: "ExternalGUID", flowlink_name: "external_guid", is_ref: false, add_only: true}
      ]

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
            <ItemDiscountQueryRq requestID="#{session_id}">
              <MaxReturned>10000</MaxReturned>
              <NameRangeFilter>
                <FromName>#{product_id}</FromName>
                <ToName>#{product_id}</ToName>
              </NameRangeFilter>
            </ItemDiscountQueryRq>
          XML
        end

        def add_xml_to_send(product, params, session_id, config)
          <<~XML
            <ItemDiscountAddRq requestID="#{session_id}">
               <ItemDiscountAdd>
                #{product_xml(product, config, false)}
               </ItemDiscountAdd>
            </ItemDiscountAddRq>
          XML
        end

        def update_xml_to_send(product, params, session_id, config)
          <<~XML
            <ItemDiscountModRq requestID="#{session_id}">
               <ItemDiscountMod>
                  <ListID>#{product['list_id']}</ListID>
                  <EditSequence>#{product['edit_sequence']}</EditSequence>
                  #{product.key?('active') ? product_only_touch_xml(product, params) : product_xml(product, config, true)}
               </ItemDiscountMod>
            </ItemDiscountModRq>
          XML
        end

        def product_only_touch_xml(product, _params)
          <<~XML
            <Name>#{product_identifier(product)}</Name>
            <IsActive>true</IsActive>
          XML
        end

        def product_xml(product, config, is_mod)
          <<~XML
            <Name>#{product_identifier(product)}</Name>
            #{add_barcode(product)}
            <IsActive >#{product['is_active'] || true}</IsActive>
            #{add_fields(product, GENERAL_MAPPING, config, is_mod)}
          XML
        end

        def polling_others_items_xml(_timestamp, _config)
          # nothing on this class
          ''
        end

        def polling_current_items_xml(params, config)
          timestamp = params['quickbooks_since']
          session_id = Persistence::Session.save(config, 'polling' => timestamp)
          time = Time.parse(timestamp).in_time_zone 'Pacific Time (US & Canada)'

          <<~XML
            <!-- polling non inventory products -->
            <ItemDiscountQueryRq requestID="#{session_id}">
              <MaxReturned>100</MaxReturned>
                #{query_by_date(params, time)}
            </ItemDiscountQueryRq>
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

        def add_fields(object, mapping, config, is_mod)
          object = object.with_indifferent_access
          fields = ""
          mapping.each do |map_item|
            next if map_item[:mod_only] && map_item[:mod_only] != is_mod
            next if map_item[:add_only] && map_item[:add_only] == is_mod

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
                                config[mapping[:flowlink_name].to_sym] ||
                                config["quickbooks_#{mapping[:flowlink_name]}".to_sym]

          full_name.nil? ? "" : "<#{qbe_field_name}><FullName>#{full_name}</FullName></#{qbe_field_name}>"
        end

        def query_by_date(config, time)
          puts "Product config for polling: #{config}"
          return '' if config['return_all'].to_i == 1

          <<~XML
            <FromModifiedDate>#{time.iso8601}</FromModifiedDate>
          XML
        end
      end
    end
  end
end
