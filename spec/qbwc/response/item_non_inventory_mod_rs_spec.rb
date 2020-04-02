require 'rspec'
require 'json'
require 'qbwc/response/item_non_inventory_mod_rs'

RSpec.describe QBWC::Response::ItemNonInventoryModRs do
  let(:expected_output) { "test-noninventory-product" }
  let(:empty_input) {
    {
      "Name" => "test-noninventory-product",
      "ParentRef" => {}
    }
  }
  let(:single_input_as_object) {
    {
      "Name" => "test-noninventory-product",
      "ParentRef" => {"FullName" => "Parent NonInventory"}
    }
  }
  let(:multi_input_as_object) {
    {
      "Name" => "test-noninventory-product",
      "ParentRef" => {"FullName" => "Super Parent NonInventory:Parent NonInventory"}
    }
  }
  let(:single_input_as_array) {
    {
      "Name" => "test-noninventory-product",
      "ParentRef" => [{"FullName" => "Parent NonInventory"}]
    }
  }
  let(:multi_input_as_array) {
    {
      "Name" => "test-noninventory-product",
      "ParentRef" => [
        {"FullName" => "Super Parent NonInventory"},
        {"FullName" => "Parent NonInventory"}
      ]
    }
  }
  
  describe "calls build_product_id_or_ref with one product returned" do
    it "has no parent product names as nil input and outputs just the product name" do
      noninventory_mod_rs = QBWC::Response::ItemNonInventoryModRs.new([{}])
      output = noninventory_mod_rs.send(:build_product_id_or_ref, {"Name" => "test-noninventory-product"})

      expect(output).to eq(expected_output)
    end

    it "has no parent product names as empty input and outputs just the product name" do
      noninventory_mod_rs = QBWC::Response::ItemNonInventoryModRs.new([{}])
      output = noninventory_mod_rs.send(:build_product_id_or_ref, empty_input)

      expect(output).to eq(expected_output)
    end

    it "has one parent product name as an object and outputs the parent name + : + product name" do
      new_expected_output = "Parent NonInventory:#{expected_output}"

      noninventory_mod_rs = QBWC::Response::ItemNonInventoryModRs.new([{}])
      output = noninventory_mod_rs.send(:build_product_id_or_ref, single_input_as_object)

      expect(output).to eq(new_expected_output)
    end

    it "has one parent product name as an array and outputs the parent name + : + product name" do
      new_expected_output = "Super Parent NonInventory:Parent NonInventory:#{expected_output}"
      
      noninventory_mod_rs = QBWC::Response::ItemNonInventoryModRs.new([{}])
      output = noninventory_mod_rs.send(:build_product_id_or_ref, multi_input_as_object)

      expect(output).to eq(new_expected_output)
    end

    it "has two parent product names as an object and outputs the parent names and product name correctly" do
      new_expected_output = "Parent NonInventory:#{expected_output}"
      
      noninventory_mod_rs = QBWC::Response::ItemNonInventoryModRs.new([{}])
      output = noninventory_mod_rs.send(:build_product_id_or_ref, single_input_as_array)

      expect(output).to eq(new_expected_output)
    end

    it "has two parent product names as an array and outputs the parent names and product name correctly" do
      new_expected_output = "Super Parent NonInventory:Parent NonInventory:#{expected_output}"
      
      noninventory_mod_rs = QBWC::Response::ItemNonInventoryModRs.new([{}])
      output = noninventory_mod_rs.send(:build_product_id_or_ref, multi_input_as_array)

      expect(output).to eq(new_expected_output)
    end
  end
end