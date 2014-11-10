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

    payload = { "notification_#{config[:object_type]}" => {} }

    integration = Persistence::Object.new config, payload
    records = integration.start_processing "integrated"

    if success = QuickbooksDesktopHelper.format_batch_response(records)
      add_value "success", success
    end

    if errors = QuickbooksDesktopHelper.format_batch_response(records, "fail")
      add_value "fail", errors
    end

    result 200
  end

  # Note that once data is returned by `start_processing` files will be moved
  # to a 'integrated' folder so chances are it will be very hard to get those
  # files back in case something explodes after this point.
  #
  # Possible issues include returning more objects than the Wombat account
  # limit allows or any ruby exception either here or once it arrives in Wombat.
  post "/get_data" do
    # TODO Drop the hardcoded account id ..
    config = { account_id: 'x123', origin: 'quickbooks' }

    s3_integration = Persistence::Object.new config
    # pass 'integrated' in case you want to move the files
    records = s3_integration.start_processing false

    if records.any?
      names = records.inject([]) do |names, collection|
        name = collection.keys.first
        add_or_merge_value name, collection.values.first

        names.push name
      end

      result 200, "Received #{names.uniq.join(', ')} records from Quickbooks"
    else
      result 200
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
