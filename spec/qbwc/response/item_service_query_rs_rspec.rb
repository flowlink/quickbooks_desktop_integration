require 'rspec'
require 'json'
require "active_support/core_ext/hash/indifferent_access"
require 'qbwc/response/item_service_query_rs'

RSpec.describe QBWC::Response::ItemServiceQueryRs do
  describe "calls objects_to_update" do
    let(:qbe_service_product) { JSON.parse(File.read('spec/qbwc/response/generic_product_fixtures/product_from_qbe.json')) }
    let(:expected_object) {
      {
        object_type: 'serviceproduct',
        object_ref: "test-product",
        product_id: "test-product",
        list_id: "80001019-2039019",
        edit_sequence: "190aMNia90jmdk"
      }
    }
    
    describe "calls objects_to_update with one product returned" do
      it "has no parent product names and outputs just the product name" do
        service_rs = QBWC::Response::ItemServiceQueryRs.new([qbe_service_product])
        output = service_rs.send(:objects_to_update).first.with_indifferent_access

        expect(output).to eq(expected_object.with_indifferent_access)
      end

      it "has one parent product name as an object and outputs the parent name + : + product name" do
        expected_object[:object_ref] = "Parent Service:test-product"
        qbe_service_product["ParentRef"] = {
          "FullName" => "Parent Service"
        }
        
        service_rs = QBWC::Response::ItemServiceQueryRs.new([qbe_service_product])
        output = service_rs.send(:objects_to_update).first.with_indifferent_access

        expect(output).to eq(expected_object.with_indifferent_access)
      end

      it "has one parent product name as an array and outputs the parent name + : + product name" do
        expected_object[:object_ref] = "Parent Service:test-product"
        qbe_service_product["ParentRef"] = [{
          "FullName" => "Parent Service"
        }]
        
        service_rs = QBWC::Response::ItemServiceQueryRs.new([qbe_service_product])
        output = service_rs.send(:objects_to_update).first.with_indifferent_access

        expect(output).to eq(expected_object.with_indifferent_access)
      end

      it "has two parent product names as an object and outputs the parent names and product name correctly" do
        expected_object[:object_ref] = "Super Parent Service:Parent Service:test-product"
        qbe_service_product["ParentRef"] = {
          "FullName" => "Super Parent Service:Parent Service"
        }
        
        service_rs = QBWC::Response::ItemServiceQueryRs.new([qbe_service_product])
        output = service_rs.send(:objects_to_update).first.with_indifferent_access

        expect(output).to eq(expected_object.with_indifferent_access)
      end

      it "has two parent product names as an array and outputs the parent names and product name correctly" do
        expected_object[:object_ref] = "Super Parent Service:Parent Service:test-product"
        qbe_service_product["ParentRef"] = [
          {"FullName" => "Super Parent Service"},
          {"FullName" => "Parent Service"}
        ]
        
        service_rs = QBWC::Response::ItemServiceQueryRs.new([qbe_service_product])
        output = service_rs.send(:objects_to_update).first.with_indifferent_access

        expect(output).to eq(expected_object.with_indifferent_access)
      end
    end
  end
end