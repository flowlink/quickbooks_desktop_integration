require 'rspec'
require 'json'
require "active_support/core_ext/hash/indifferent_access"
require 'qbwc/response/item_discount_query_rs'

RSpec.describe QBWC::Response::ItemDiscountQueryRs do
  let(:qbe_discount_product) { JSON.parse(File.read('spec/qbwc/response/discountproduct_fixtures/product_from_qbe.json')) }
  let(:expected_object) {
    {
      object_type: 'discountproduct',
      object_ref: "test-discount-product",
      product_id: "test-discount-product",
      list_id: "80001019-2039019",
      edit_sequence: "190aMNia90jmdk"
    }
  }
  
  describe "calls objects_to_update" do
    describe "with one product returned" do
      describe "with no parent product names and" do
        it "outputs just the product name" do
          discount_rs = QBWC::Response::ItemDiscountQueryRs.new([qbe_discount_product])
          output = discount_rs.send(:objects_to_update).first.with_indifferent_access

          expect(output).to eq(expected_object.with_indifferent_access)
        end
      end
    end
  end
end