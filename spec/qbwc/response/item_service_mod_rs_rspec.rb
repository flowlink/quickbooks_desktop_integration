require 'rspec'
require 'json'
require 'qbwc/response/item_service_mod_rs'

RSpec.describe QBWC::Response::ItemServiceModRs do
  let(:expected_output) { "test-service-product" }
  let(:empty_input) {
    {
      "Name" => "test-service-product",
      "ParentRef" => {}
    }
  }
  let(:single_input_as_object) {
    {
      "Name" => "test-service-product",
      "ParentRef" => {"FullName" => "Parent Service"}
    }
  }
  let(:multi_input_as_object) {
    {
      "Name" => "test-service-product",
      "ParentRef" => {"FullName" => "Super Parent Service:Parent Service"}
    }
  }
  let(:single_input_as_array) {
    {
      "Name" => "test-service-product",
      "ParentRef" => [{"FullName" => "Parent Service"}]
    }
  }
  let(:multi_input_as_array) {
    {
      "Name" => "test-service-product",
      "ParentRef" => [
        {"FullName" => "Super Parent Service"},
        {"FullName" => "Parent Service"}
      ]
    }
  }
  
  describe "calls build_product_id_or_ref with one product returned" do
    it "has no parent product names as nil input and outputs just the product name" do
      service_mod_rs = QBWC::Response::ItemServiceModRs.new([{}])
      output = service_mod_rs.send(:build_product_id_or_ref, {"Name" => "test-service-product"})

      expect(output).to eq(expected_output)
    end

    it "has no parent product names as empty input and outputs just the product name" do
      service_mod_rs = QBWC::Response::ItemServiceModRs.new([{}])
      output = service_mod_rs.send(:build_product_id_or_ref, empty_input)

      expect(output).to eq(expected_output)
    end

    it "has one parent product name as an object and outputs the parent name + : + product name" do
      new_expected_output = "Parent Service:#{expected_output}"

      service_mod_rs = QBWC::Response::ItemServiceModRs.new([{}])
      output = service_mod_rs.send(:build_product_id_or_ref, single_input_as_object)

      expect(output).to eq(new_expected_output)
    end

    it "has one parent product name as an array and outputs the parent name + : + product name" do
      new_expected_output = "Super Parent Service:Parent Service:#{expected_output}"
      
      service_mod_rs = QBWC::Response::ItemServiceModRs.new([{}])
      output = service_mod_rs.send(:build_product_id_or_ref, multi_input_as_object)

      expect(output).to eq(new_expected_output)
    end

    it "has two parent product names as an object and outputs the parent names and product name correctly" do
      new_expected_output = "Parent Service:#{expected_output}"
      
      service_mod_rs = QBWC::Response::ItemServiceModRs.new([{}])
      output = service_mod_rs.send(:build_product_id_or_ref, single_input_as_array)

      expect(output).to eq(new_expected_output)
    end

    it "has two parent product names as an array and outputs the parent names and product name correctly" do
      new_expected_output = "Super Parent Service:Parent Service:#{expected_output}"
      
      service_mod_rs = QBWC::Response::ItemServiceModRs.new([{}])
      output = service_mod_rs.send(:build_product_id_or_ref, multi_input_as_array)

      expect(output).to eq(new_expected_output)
    end
  end
end