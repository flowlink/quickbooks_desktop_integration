require 'spec_helper'

describe QuickbooksDesktopEndpoint do
  it "send orders to s3" do
    request = Factory.orders

    allow_any_instance_of(Service::Object).to receive(:current_time).and_return('1415157575')

    VCR.use_cassette "add_orders/1414614344" do
      post "add_orders", request.to_json, auth
      expect(json_response[:summary]).to match "waiting for"
      expect(last_response.status).to be 200
    end
  end

  # keeping this here just as a suggestion, this endpoint will live in qbwc_endoint
  #
  # it "save callback response as notifications to s3" do
  #   request = {
  #     "connection_id" => "x123",
  #     "response" => [
  #       {
  #         "result" => "fail",
  #         "object_ref" => "1414728530",
  #         "summary" => "1414728530 object notification yay message"
  #       }
  #     ]
  #   }

  #   VCR.use_cassette "requests/1414728530" do
  #     post "/qb_response_callback", request.to_json
  #     expect(json_response[:summary]).to eq nil
  #     expect(last_response.status).to eq 200
  #   end
  # end

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

  it "gets data from quickbooks" do
    headers = auth.merge("HTTP_X_HUB_STORE" => "54591b3a5869632afc090000")
    request = {
      parameters: {
        quickbooks_since: '2014-11-10T09:10:55Z',
        quickbooks_force_config: 0
      }
    }
    
    VCR.use_cassette "requests/425435435234532" do
      post "/get_inventory", request.to_json, headers

      expect(json_response[:summary]).to match "records from quickbooks"
      expect(last_response.status).to eq 200
      expect(json_response[:inventories].count).to be >= 1
    end
  end

  it "gets no data" do
    VCR.use_cassette "requests/43535345325" do
      post "/get_data", {}.to_json, auth
      expect(json_response[:summary]).to eq nil
      expect(last_response.status).to eq 200
    end
  end
end
