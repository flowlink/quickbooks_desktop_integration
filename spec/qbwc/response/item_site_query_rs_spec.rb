require 'rspec'
require 'json'
require "active_support/core_ext/hash/indifferent_access"
require 'qbwc/response/item_site_query_rs'

RSpec.describe QBWC::Response::ItemSitesQueryRs do
  describe "calls inventories_to_flowlink" do
    let(:inventory_object) { JSON.parse(File.read('spec/qbwc/response/item_site_fixtures/item_site.json')) }
    let(:assembly_object) { JSON.parse(File.read('spec/qbwc/response/item_site_fixtures/item_site_assembly.json')) }
    let(:expected_inventory) {
        {
          "list_id": "",
          "created_at" => "2015-02-04T17:22:56-05:00",
          "updated_at" => "2015-02-04T17:22:56-05:00",
          "edit_sequence" => "1423088576",
          "full_name": "BOIL-OUT 4",
          "assembly_item_name" => "",
          "inventory_item_name" => "BOIL-OUT 4",
          "qbe_item_type" => "qbe_inventory",
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
    let(:expected_assembly) {
        {
          "list_id": "",
          "created_at" => "2015-02-04T17:22:56-05:00",
          "updated_at" => "2015-02-04T17:22:56-05:00",
          "edit_sequence" => "1423088576",
          "full_name": "BOIL-OUT 4",
          "assembly_item_name" => "BOIL-OUT 4",
          "inventory_item_name" => "",
          "qbe_item_type" => "inventory_assembly",
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
    
    describe "calls inventories_to_flowlink with one inventory returned" do
      it "returns fields specific to inventory items" do
        service_rs = QBWC::Response::ItemSitesQueryRs.new([inventory_object])
        output = service_rs.send(:inventories_to_flowlink).first.with_indifferent_access
        expect(output).to eq(expected_inventory.with_indifferent_access)

      end

      it "returns fields specific to assembly items" do
        service_rs = QBWC::Response::ItemSitesQueryRs.new([assembly_object])
        output = service_rs.send(:inventories_to_flowlink).first.with_indifferent_access
        expect(output).to eq(expected_assembly.with_indifferent_access)

      end
    end

  end
end
