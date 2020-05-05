require 'endpoint_base'
require 'sinatra/reloader'
require 'securerandom'

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
  get_vendors
  get_noninventoryproducts
  get_serviceproducts
  get_salestaxproducts
  get_discountproducts
  get_inventoryproducts
  get_inventoryassemblyproducts
  get_otherchargeproducts
)

CUSTOM_OBJECT_TYPES = %w(
  inventorywithsites
  otherchargeproducts
)

OBJECT_TYPES_MAPPING_DATA_OBJECT = {
  'inventorywithsites' => 'inventories',
  'otherchargeproducts' => 'products'
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

      already_has_guid?
      generate_and_add_guid unless @already_has_guid

      integration = Persistence::Object.new(config, @payload)
      integration.save
      
      add_object integration.payload_key, add_flow_return_payload unless @already_has_guid

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
      records = persistence.process_waiting_records
      integration = Persistence::Object.new config, @payload
      notifications = integration.get_notifications

      add_value 'success', notifications['processed'] if !notifications['processed'].empty?
      add_value 'fail', notifications['failed'] if !notifications['failed'].empty?
      if records.any?
        names = records.inject([]) do |names, collection|
          name = collection.keys.first
          puts name
          puts collection.values.first.inspect

          if CUSTOM_OBJECT_TYPES.include? name
            add_or_merge_value OBJECT_TYPES_MAPPING_DATA_OBJECT[name], collection.values.first
          else
            add_or_merge_value name, collection.values.first
          end

          names.push name
        end

        params = s3_settings.fetch(path).first[object_type]
        add_parameter 'quickbooks_since', params['quickbooks_since']

        result 200, "Received #{names.uniq.join(', ')} records from quickbooks"
      else
        result 200
      end
    end
  end

  private

  def add_flow_return_payload
    {
      id: @payload[object_type][:id],
      external_guid: @payload[object_type][:external_guid]
    }
  end

  def generate_and_add_guid
    @payload[object_type][:external_guid] = "{#{SecureRandom.uuid.upcase}}"
  end

  def object_type
    @payload[:parameters][:payload_type]
  end

  def already_has_guid?
    @already_has_guid ||= @payload[object_type][:external_guid] && @payload[object_type][:external_guid] != ""
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
