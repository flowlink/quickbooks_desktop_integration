require 'rspec'
require 'json'
require 'qbwc/response/item_inventory_add_rs'

RSpec.describe QBWC::Response::ItemInventoryAddRs do
  let(:expected_output) { "test-inventory-product" }
  let(:empty_input) {
    {
      "Name" => "test-inventory-product",
      "ParentRef" => {}
    }
  }
  let(:single_input_as_object) {
    {
      "Name" => "test-inventory-product",
      "ParentRef" => {"FullName" => "Parent Inventory"}
    }
  }
  let(:multi_input_as_object) {
    {
      "Name" => "test-inventory-product",
      "ParentRef" => {"FullName" => "Super Parent Inventory:Parent Inventory"}
    }
  }
  let(:single_input_as_array) {
    {
      "Name" => "test-inventory-product",
      "ParentRef" => [{"FullName" => "Parent Inventory"}]
    }
  }
  let(:multi_input_as_array) {
    {
      "Name" => "test-inventory-product",
      "ParentRef" => [
        {"FullName" => "Super Parent Inventory"},
        {"FullName" => "Parent Inventory"}
      ]
    }
  }
  
  describe "calls build_product_id_or_ref with one product returned" do
    it "has no parent product names as nil input and outputs just the product name" do
      inventory_add_rs = QBWC::Response::ItemInventoryAddRs.new([{}])
      output = inventory_add_rs.send(:build_product_id_or_ref, {"Name" => "test-inventory-product"})

      expect(output).to eq(expected_output)
    end

    it "has no parent product names as empty input and outputs just the product name" do
      inventory_add_rs = QBWC::Response::ItemInventoryAddRs.new([{}])
      output = inventory_add_rs.send(:build_product_id_or_ref, empty_input)

      expect(output).to eq(expected_output)
    end

    it "has one parent product name as an object and outputs the parent name + : + product name" do
      new_expected_output = "Parent Inventory:#{expected_output}"

      inventory_add_rs = QBWC::Response::ItemInventoryAddRs.new([{}])
      output = inventory_add_rs.send(:build_product_id_or_ref, single_input_as_object)

      expect(output).to eq(new_expected_output)
    end

    it "has one parent product name as an array and outputs the parent name + : + product name" do
      new_expected_output = "Super Parent Inventory:Parent Inventory:#{expected_output}"
      
      inventory_add_rs = QBWC::Response::ItemInventoryAddRs.new([{}])
      output = inventory_add_rs.send(:build_product_id_or_ref, multi_input_as_object)

      expect(output).to eq(new_expected_output)
    end

    it "has two parent product names as an object and outputs the parent names and product name correctly" do
      new_expected_output = "Parent Inventory:#{expected_output}"
      
      inventory_add_rs = QBWC::Response::ItemInventoryAddRs.new([{}])
      output = inventory_add_rs.send(:build_product_id_or_ref, single_input_as_array)

      expect(output).to eq(new_expected_output)
    end

    it "has two parent product names as an array and outputs the parent names and product name correctly" do
      new_expected_output = "Super Parent Inventory:Parent Inventory:#{expected_output}"
      
      inventory_add_rs = QBWC::Response::ItemInventoryAddRs.new([{}])
      output = inventory_add_rs.send(:build_product_id_or_ref, multi_input_as_array)

      expect(output).to eq(new_expected_output)
    end
  end
end