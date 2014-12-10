require 'endpoint_base'

require File.expand_path(File.dirname(__FILE__) + '/lib/quickbooks_desktop_integration')

class QuickbooksDesktopEndpoint < EndpointBase::Sinatra::Base
  set :logging, true

  # Changing the endpoint paths might break internal logic as they're expected
  # to be always in plural. e.g. products not product

  ['products', 'orders', 'returns', 'customers', 'shipments'].each do |path|
    post "/add_#{path}" do
      config = {
        connection_id: request.env['HTTP_X_HUB_STORE'],
        flow: "add_#{path}",
        # NOTE could save us some time and http calls by not persisting configs
        # on every call. Use same approach on polling instead by always setting
        # this flag back to false on return?
        quickbooks_force_config: true
      }.merge(@config).with_indifferent_access

      Persistence::Settings.new(config).setup

      integration = Persistence::Object.new config, @payload
      integration.save

      notifications = integration.get_notifications

      add_value "success", notifications['processed'] if notifications['processed'].keys.any?
      add_value "fail", notifications['failed'] if notifications['failed'].keys.any?

      object_type = integration.payload_key.capitalize
      result 200, "#{object_type} waiting for Quickbooks Desktop scheduler"
    end
  end

  post "/set_inventory" do
    config = {
      connection_id: request.env['HTTP_X_HUB_STORE'],
      flow: "set_inventory"
    }.merge(@config).with_indifferent_access

    Persistence::Settings.new(config).setup

    integration = Persistence::Object.new config, @payload
    integration.save

    notifications = integration.get_notifications

    add_value "success", notifications['processed'] if notifications['processed'].keys.any?
    add_value "fail", notifications['failed'] if notifications['failed'].keys.any?

    object_type = integration.payload_key.capitalize
    result 200, "#{object_type} waiting for Quickbooks Desktop scheduler"
  end

  post "/get_notifications" do
    # THIS IS NOT USED, just to not confuse

    # NOTE Confirm this would be the same sent in the Send webhooks
    # config = @config.merge connection_id: request.env['HTTP_X_HUB_STORE']

    # object_type = @payload.keys.first

    # payload       = { object_type.pluralize => nil }
    # integration   = Persistence::Object.new config, payload
    # notifications = integration.get_notifications

    # add_value "success", { "Object successfully received in batch" => notifications['processed'] }
    # add_value "fail", { "Error to process objects in quickbooks" => notifications['failed'] }

    # result 200
  end

  ["get_inventory", "get_inventories", "get_products"].each do |path|
    post "/#{path}" do
      object_type = path.split("_").last.pluralize

      config = {
        connection_id: request.env['HTTP_X_HUB_STORE'],
        flow: path,
        origin: "quickbooks"
      }.merge(@config).with_indifferent_access

      s3_settings = Persistence::Settings.new(config)
      s3_settings.setup

      add_parameter "quickbooks_force_config", false

      persistence = Persistence::Object.new config, object_type => {}
      records = persistence.process_waiting_records

      if records.any?
        names = records.inject([]) do |names, collection|
          name = collection.keys.first
          add_or_merge_value name, collection.values.first

          names.push name
        end

        params = s3_settings.fetch(path).first[object_type]
        add_parameter "quickbooks_since", params['quickbooks_since']

        result 200, "Received #{names.uniq.join(', ')} records from quickbooks"
      else
        result 200
      end
    end
  end

  private
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

        @attrs[name] = group.map { |k, v| v.reduce(:merge) }
      end
    end
end
