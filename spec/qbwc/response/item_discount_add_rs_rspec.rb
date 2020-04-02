require 'rspec'
require 'json'
require 'qbwc/response/item_discount_add_rs'

RSpec.describe QBWC::Response::ItemDiscountAddRs do
  let(:expected_output) { "test-discount-product" }
  let(:empty_input) {
    {
      "Name" => "test-discount-product",
      "ParentRef" => {}
    }
  }
  let(:single_input_as_object) {
    {
      "Name" => "test-discount-product",
      "ParentRef" => {"FullName" => "Parent Discount"}
    }
  }
  let(:multi_input_as_object) {
    {
      "Name" => "test-discount-product",
      "ParentRef" => {"FullName" => "Super Parent Discount:Parent Discount"}
    }
  }
  let(:single_input_as_array) {
    {
      "Name" => "test-discount-product",
      "ParentRef" => [{"FullName" => "Parent Discount"}]
    }
  }
  let(:multi_input_as_array) {
    {
      "Name" => "test-discount-product",
      "ParentRef" => [
        {"FullName" => "Super Parent Discount"},
        {"FullName" => "Parent Discount"}
      ]
    }
  }
  
  describe "calls build_product_id_or_ref with one product returned" do
    it "has no parent product names as nil input and outputs just the product name" do
      discount_add_rs = QBWC::Response::ItemDiscountAddRs.new([{}])
      output = discount_add_rs.send(:build_product_id_or_ref, {"Name" => "test-discount-product"})

      expect(output).to eq(expected_output)
    end

    it "has no parent product names as empty input and outputs just the product name" do
      discount_add_rs = QBWC::Response::ItemDiscountAddRs.new([{}])
      output = discount_add_rs.send(:build_product_id_or_ref, empty_input)

      expect(output).to eq(expected_output)
    end

    it "has one parent product name as an object and outputs the parent name + : + product name" do
      new_expected_output = "Parent Discount:#{expected_output}"

      discount_add_rs = QBWC::Response::ItemDiscountAddRs.new([{}])
      output = discount_add_rs.send(:build_product_id_or_ref, single_input_as_object)

      expect(output).to eq(new_expected_output)
    end

    it "has one parent product name as an array and outputs the parent name + : + product name" do
      new_expected_output = "Super Parent Discount:Parent Discount:#{expected_output}"
      
      discount_add_rs = QBWC::Response::ItemDiscountAddRs.new([{}])
      output = discount_add_rs.send(:build_product_id_or_ref, multi_input_as_object)

      expect(output).to eq(new_expected_output)
    end

    it "has two parent product names as an object and outputs the parent names and product name correctly" do
      new_expected_output = "Parent Discount:#{expected_output}"
      
      discount_add_rs = QBWC::Response::ItemDiscountAddRs.new([{}])
      output = discount_add_rs.send(:build_product_id_or_ref, single_input_as_array)

      expect(output).to eq(new_expected_output)
    end

    it "has two parent product names as an array and outputs the parent names and product name correctly" do
      new_expected_output = "Super Parent Discount:Parent Discount:#{expected_output}"
      
      discount_add_rs = QBWC::Response::ItemDiscountAddRs.new([{}])
      output = discount_add_rs.send(:build_product_id_or_ref, multi_input_as_array)

      expect(output).to eq(new_expected_output)
    end
  end
end