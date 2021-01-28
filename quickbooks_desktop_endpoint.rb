require 'endpoint_base'
require 'sinatra/reloader'
require 'securerandom'

require 'honeybadger'

require File.expand_path(File.dirname(__FILE__) + '/lib/quickbooks_desktop_integration')

ENDPOINTS = %w(
  add_salesreceipts
  add_payments
  add_products
  add_purchaseorders
  add_orders
  add_invoices
  add_returns
  add_customers
  add_shipments
  cancel_order
  add_journals
  add_vendors
  add_noninventoryproducts
  add_serviceproducts
  add_salestaxproducts
  add_discountproducts
  add_otherchargeproducts
  add_creditmemos
  add_creditmemosaspayments
)

GET_ENDPOINTS =  %w(
  get_inventory
  get_inventorywithsites
  get_inventories
  get_products
  get_invoices
  get_purchaseorders
  get_customers
  get_orders
  get_salesreceipts
  get_vendors
  get_noninventoryproducts
  get_serviceproducts
  get_salestaxproducts
  get_discountproducts
  get_inventoryproducts
  get_inventoryassemblyproducts
  get_otherchargeproducts
  get_creditmemos
)

CUSTOM_OBJECT_TYPES = %w(
  inventorywithsites
  serviceproducts
  noninventoryproducts
  salestaxproducts
  discountproducts
  inventoryproducts
  inventoryassemblyproducts
  otherchargeproducts
  purchaseorders
  salesreceipts
  creditmemos
)

OBJECT_TYPES_MAPPING_DATA_OBJECT = {
  'inventorywithsites' => 'inventories',
  'otherchargeproducts' => 'products',
  'serviceproducts' => 'products',
  'salestaxproducts' => 'products',
  'noninventoryproducts' => 'products',
  'inventoryproducts' => 'products',
  'discountproducts' => 'products',
  'inventoryassemblyproducts' => 'products',
  'purchaseorders' => 'purchase_orders',
  'salesreceipts' => 'sales_receipts',
  'creditmemos' => 'credit_memos'
}

class QuickbooksDesktopEndpoint < EndpointBase::Sinatra::Base
  set :logging, true

  # Force Sinatra to autoreload this file or any file in the lib directory
  # when they change in development
  configure :development do
    register Sinatra::Reloader
    also_reload './lib/**/*'
  end

  # Changing the endpoint paths might break internal logic as they're expected
  # to be always in plural. e.g. products not product

  ENDPOINTS.each do |path|
    post "/#{path}" do
      config = {
        connection_id: request.env['HTTP_X_HUB_STORE'],
        flow: "#{path}",
        # NOTE could save us some time and http calls by not persisting configs
        # on every call. Use same approach on polling instead by always setting
        # this flag back to false on return?
        quickbooks_force_config: 'true'
      }.merge(@config).with_indifferent_access

      Persistence::Settings.new(config).setup

      @return_payload = nil

      add_return_attributes_to_return_payload

      unless already_has_guid?
        generate_and_add_guid
      end
      
      add_flow_return_payload if @return_payload

      integration = Persistence::Object.new(config, @payload)
      integration.save

      object_type = integration.payload_key.capitalize
      result 200, "#{object_type} waiting for Quickbooks Desktop scheduler"
    end
  end

  post '/get_notifications' do
    config = {
      connection_id: request.env['HTTP_X_HUB_STORE'],
      flow: "get_notifications",
      quickbooks_force_config: 'true'
    }.merge(@config).with_indifferent_access

    integration = Persistence::Object.new config, @payload
    notifications = integration.get_notifications

    add_value 'success', notifications['processed'] if !notifications['processed'].empty?
    add_value 'fail', notifications['failed'] if !notifications['failed'].empty?

    result 200, "Notifications retrieved"
  end

  post '/get_health_check' do
    config = {
      connection_id: request.env['HTTP_X_HUB_STORE'],
      flow: "get_health_check",
      quickbooks_force_config: 'true'
    }.merge(@config).with_indifferent_access

    s3_settings = Persistence::Settings.new(config)
    if s3_settings.healthceck_is_failing?
      result 500, "Health check was not successful"
    else
      result 200, "Health check was successful"
    end
  end

  post '/set_inventory' do
    config = {
      connection_id: request.env['HTTP_X_HUB_STORE'],
      flow: 'set_inventory'
    }.merge(@config).with_indifferent_access

    Persistence::Settings.new(config).setup

    integration = Persistence::Object.new config, @payload
    integration.save

    notifications = integration.get_notifications

    add_value 'success', notifications['processed'] if !notifications['processed'].empty?
    add_value 'fail', notifications['failed'] if !notifications['failed'].empty?

    object_type = integration.payload_key.capitalize
    result 200, "Inventory waiting for Quickbooks Desktop scheduler"
  end

  GET_ENDPOINTS.each do |path|
    post "/#{path}" do
      object_type = path.split('_').last.pluralize

      config = {
        connection_id: request.env['HTTP_X_HUB_STORE'],
        flow: path,
        origin: 'quickbooks'
      }.merge(@config).with_indifferent_access

      s3_settings = Persistence::Settings.new(config)
      s3_settings.setup

      add_parameter 'quickbooks_force_config', false

      persistence = Persistence::Polling.new config, @payload, object_type
      records, done = persistence.process_waiting_records

      integration = Persistence::Object.new config, @payload
      notifications = integration.get_notifications

      add_value 'success', notifications['processed'] if !notifications['processed'].empty?
      add_value 'fail', notifications['failed'] if !notifications['failed'].empty?
      if records.any?
        names = records.inject([]) do |names, collection|
          name = collection.keys.first
          puts name
          puts collection.values.first.inspect

          records = collection.values.first


          puts({connection_id: @config['connection_id'], flow: @config['flow'], records: records.inspect})
          records = records.map{|record| allow_only_whitelisted_fields(record.with_indifferent_access) }

          add_or_merge_value determine_name(name), records

          names.push name
        end

        params = s3_settings.fetch(path).first[object_type]
        add_parameter 'quickbooks_since', params['quickbooks_since']

        status = done ? 200 : 206

        result status, "Received #{names.uniq.join(', ')} records from quickbooks"
      else
        result 200
      end
    end
  end

  private

  def determine_name(name)
    plural_name = name.pluralize
    return name unless CUSTOM_OBJECT_TYPES.include?(plural_name)
    
    OBJECT_TYPES_MAPPING_DATA_OBJECT[plural_name]
  end

  # NOTE: ideally this would live in endpoint_base gem,
  # but it is the first time it appears
  # it expects config['fields_whitelist'] to be a string of comma separated attrs
  # i.e. "id, list_id, external_guid"
  def allow_only_whitelisted_fields(record)
    return record unless @config['fields_whitelist'] 
    puts({connection_id: @config['connection_id'], whitelisted_fields: @config['fields_whitelist'], flow: @config['flow'], record: record.inspect})

    params_list = @config['fields_whitelist'].split(",").map(&:strip).map(&:to_sym)

    # so id is not forgotten
    params_list = (params_list << :id).uniq

    new_record = {}

    params_list.each do |param|
      new_record[param] = record[param]
    end

    new_record
  end
  
  def add_flow_return_payload
    payload = @return_payload.merge({
      id: @payload[object_type][:id]
    })
    add_object determine_name(object_type).singularize, payload
  end

  def generate_and_add_guid
    @return_payload ||= {}
    guid = "{#{SecureRandom.uuid.upcase}}"

    @payload[object_type][:external_guid] = guid
    @return_payload[:external_guid] = guid
  end

  def add_return_attributes_to_return_payload
    @return_payload = @payload[object_type][:return_to_fl] if @payload[object_type][:return_to_fl].is_a?(Hash)
  end

  def object_type
    @payload[:parameters][:payload_type]
  end

  def already_has_guid?
    # We need to tie the object in FL to the external ID
    # UNLESS the object originated in QBE!
    # You can't MOD an external_guid, so we don't set if the object has a QBE ID
    (@payload[object_type][:external_guid] && @payload[object_type][:external_guid] != "") ||
    (@payload[object_type][:qbe_id] && @payload[object_type][:qbe_id] != "")
  end

  # NOTE this lives in endpoint_base. Added here just so it's closer ..
  # once we sure it's stable merge and push to endpoint_base/master
  # and bump it here
  def add_or_merge_value(name, value)
    @attrs ||= {}

    unless @attrs[name]
      @attrs[name] = value
    else
      old_value = @attrs[name]

      collection = (old_value + value).flatten
      group = collection.group_by { |h| h[:id] || h['id'] }

      @attrs[name] = group.map { |_k, v| v.reduce(:merge) }
    end
  end
end
