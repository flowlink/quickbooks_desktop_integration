require 'rspec'
require 'json'
require "active_support/core_ext/hash/indifferent_access"
require 'qbwc/response/item_site_query_rs'

RSpec.describe QBWC::Response::ItemSitesQueryRs do
  describe "calls objects_to_update" do
    let(:given_object) { JSON.parse(File.read('spec/qbwc/response/item_site_fixtures/item_site.json')) }
    let(:expected_object) {
        {
          "list_id": "",
          "created_at" => "2015-02-04T17:22:56-05:00",
          "updated_at" => "2015-02-04T17:22:56-05:00",
          "edit_sequence" => "1423088576",
          "full_name": "BOIL-OUT 4",
          "quantity_on_hand": "12",
          "inventory_site": "DFW",
          "inventory_site_location": "",
          "quantity_on_po": "0",
          "quantity_on_sales_order": "0",
          "quantity_to_be_assembled": "0",
          "quantity_by_being_assembled": "0",
          "quantity_by_pending_transfer": "0"
        }
    }
    
    describe "calls objects_to_update with one product returned" do
      it "has no parent product names and outputs just the product name" do
        service_rs = QBWC::Response::ItemSitesQueryRs.new([given_object])
        output = service_rs.send(:inventories_to_flowlink).first.with_indifferent_access
        expect(output).to eq(expected_object.with_indifferent_access)

      end
    end

  end
end
