require 'endpoint_base'

require File.expand_path(File.dirname(__FILE__) + '/lib/quickbooks_desktop_integration')

class QuickbooksDesktopEndpoint < EndpointBase::Sinatra::Base
  set :logging, true

  ['products', 'orders', 'inventory', 'returns', 'customers'].each do |path|
    post "/add_#{path}" do
      config = @config.merge connection_id: request.env["HTTP_X_HUB_STORE"]
      integration = QuickbooksDesktopIntegration::Base.new config, @payload
      integration.save_to_s3

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

    integration = QuickbooksDesktopIntegration::Base.new config, payload
    integration.save_to_s3
    result 200
  end

  post "/get_notifications" do
    # NOTE Confirm this would be the same sent in the Send webhooks
    config = @config.merge connection_id: request.env["HTTP_X_HUB_STORE"]
    payload = { "notification_#{config[:object_type]}" => {} }

    integration = QuickbooksDesktopIntegration::Base.new config, payload
    records = integration.start_processing "integrated"

    if success = QuickbooksDesktopHelper.format_batch_response(records)
      add_value "success", success
    end

    if errors = QuickbooksDesktopHelper.format_batch_response(records, "fail")
      add_value "fail", errors
    end

    result 200
  end

  post "/get_inventory" do
    # TODO Drop the hardcoded account id ..
    config = { account_id: 'x123', origin: 'quickbooks' }
    payload = { inventories: {} }

    integration = QuickbooksDesktopIntegration::Base.new config, payload
    inventories = integration.start_processing "integrated"

    if inventories.any?
      count = inventories.count
      add_value 'inventories', inventories
      result 200, "Received #{count} #{"inventory".pluralize count} from Quickbooks Desktop"
    else
      result 200
    end
  end

  post %r{(add_product|update_product)$} do
    # TODO Drop the hardcoded account id ..
    config = { account_id: 'x123', origin: 'quickbooks' }
    payload = { products: {} }

    integration = QuickbooksDesktopIntegration::Base.new config, payload
    products = integration.start_processing "integrated"

    if products.any?
      count = products.count
      add_value 'products', products
      result 200, "#{"product".pluralize count} stored to send to Quickbooks Desktop"
    else
      result 200
    end
  end

end
