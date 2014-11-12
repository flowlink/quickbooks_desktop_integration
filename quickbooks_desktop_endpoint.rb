require 'endpoint_base'

require File.expand_path(File.dirname(__FILE__) + '/lib/quickbooks_desktop_integration')

class QuickbooksDesktopEndpoint < EndpointBase::Sinatra::Base
  set :logging, true

  ['products', 'orders', 'inventory', 'returns', 'customers'].each do |path|
    post "/add_#{path}" do
      config = { connection_id: request.env['HTTP_X_HUB_STORE'] }
      integration = Persistence::Object.new config, @payload

      integration.save

      object_type = integration.payload_key.capitalize
      result 200, "#{object_type} waiting for Quickbooks Desktop scheduler"
    end
  end

  # Quickbooks will hit this endpoint to tell us about the last object batch
  #
  # POST or GET?
  #
  # NOTE Need to figure how exactly this request will look like.
  # Assume we get a message with some kind of reference to the last
  # file (object or batch of objects) sent a status and or a successful or
  # error message
  post "/qb_response_callback" do
    config = { connection_id: @payload[:connection_id] }
    payload = { notification_orders: @payload[:response] }

    integration = Persistence::Object.new config, payload
    integration.save
    result 200
  end

  post "/get_notifications" do
    # NOTE Confirm this would be the same sent in the Send webhooks
    config = @config.merge connection_id: request.env['HTTP_X_HUB_STORE']

    payload = { @payload[:response] => nil }
    integration = Persistence::Object.new config, payload
    notifications = integration.get_notifications

    add_value "success", notifications['processed']
    add_value "fail", notifications['failed']

    result 200
  end

  ["get_inventories", "get_products"].each do |path|
    post "/#{path}" do
      object_type = path.split("_").last

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
