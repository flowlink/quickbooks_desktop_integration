require 'spec_helper'

describe QuickbooksDesktopEndpoint do
  it "send orders to s3" do
    request = Factory.orders
    headers = auth.merge("HTTP_X_HUB_STORE" => "x123")

    VCR.use_cassette "add_orders/1414614344" do
      post "add_orders", request.to_json, headers
      expect(json_response[:summary]).to match "waiting for"
      expect(last_response.status).to be 200
    end
  end

  it "save callback response as notifications to s3" do
    request = {
      "connection_id" => "x123",
      "response" => [
        {
          "result" => "fail",
          "object_ref" => "1414728530",
          "summary" => "1414728530 object notification yay message"
        }
      ]
    }

    VCR.use_cassette "requests/1414728530" do
      post "/qb_response_callback", request.to_json
      expect(json_response[:summary]).to eq nil
      expect(last_response.status).to eq 200
    end
  end

  it "returns notifications in batch format" do
    headers = auth.merge("HTTP_X_HUB_STORE" => "x123")

    request = {
      parameters: {
        object_type: "orders"
      }
    }

    VCR.use_cassette "requests/334534253425" do
      post "/get_notifications", request.to_json, headers
      expect(json_response[:summary]).to eq nil
      expect(last_response.status).to eq 200
    end
  end

  it "gets inventory" do
    VCR.use_cassette "requests/438787962387562345" do
      post "/get_inventory", {}.to_json, auth
      expect(json_response[:summary]).to match "inventories from Quickbooks Desktop"
      expect(last_response.status).to eq 200
      expect(json_response[:inventories].count).to be >= 1
    end
  end

  it "gets no inventory" do
    VCR.use_cassette "requests/43535345325" do
      post "/get_inventory", {}.to_json, auth
      expect(json_response[:summary]).to eq nil
      expect(last_response.status).to eq 200
    end
  end
end
