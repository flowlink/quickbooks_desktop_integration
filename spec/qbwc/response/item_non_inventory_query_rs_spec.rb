require 'rspec'
require 'json'
require "active_support/core_ext/hash/indifferent_access"
require 'qbwc/response/item_non_inventory_query_rs'

RSpec.describe QBWC::Response::ItemNonInventoryQueryRs do
  describe "calls products_to_flowlink" do
    let(:sandp_qbe_product) { JSON.parse(File.read('spec/qbwc/response/noninventory_product_fixtures/sales_and_purchase_prod_from_qbe.json')) }
    let(:sorp_qbe_product) { JSON.parse(File.read('spec/qbwc/response/noninventory_product_fixtures/sales_or_purchase_prod_from_qbe.json')) }
    
    let(:base_flowlink_product) { JSON.parse(File.read('spec/qbwc/response/noninventory_product_fixtures/noninventoryproduct_output.json')) }
    let(:fl_sales_and_purchase) { JSON.parse(File.read('spec/qbwc/response/noninventory_product_fixtures/sales_and_purchase_output.json')) }
    let(:fl_sales_or_purchase_with_percent) { JSON.parse(File.read('spec/qbwc/response/noninventory_product_fixtures/sales_or_purchase_with_percent_output.json')) }
    let(:fl_sales_or_purchase_without_percent) { JSON.parse(File.read('spec/qbwc/response/noninventory_product_fixtures/sales_or_purchase_no_percent_output.json')) }

    it "with a payload of a sales and purchase product and outputs the right data" do
      expected_product = base_flowlink_product.merge(fl_sales_and_purchase).compact

      non_inv_rs = QBWC::Response::ItemNonInventoryQueryRs.new([sandp_qbe_product])
      output = non_inv_rs.send(:products_to_flowlink).first.with_indifferent_access

      expect(output).to eq(expected_product.with_indifferent_access)
    end

    describe "with a payload of a sales or purchase product" do
      it "with price and outputs the right data" do
        expected_product = base_flowlink_product.merge(fl_sales_or_purchase_without_percent).compact
        
        sorp_qbe_product["SalesOrPurchase"]["Price"] = 100
        non_inv_rs = QBWC::Response::ItemNonInventoryQueryRs.new([sorp_qbe_product])
        output = non_inv_rs.send(:products_to_flowlink).first.with_indifferent_access

        expect(output).to eq(expected_product.with_indifferent_access)
      end

      it "with price percent and outputs the right data" do
        expected_product = base_flowlink_product.merge(fl_sales_or_purchase_with_percent).compact

        sorp_qbe_product["SalesOrPurchase"]["PricePercent"] = 100
        non_inv_rs = QBWC::Response::ItemNonInventoryQueryRs.new([sorp_qbe_product])
        output = non_inv_rs.send(:products_to_flowlink).first.with_indifferent_access

        puts expected_product

        expect(output).to eq(expected_product.with_indifferent_access)
      end
    end
  end

  describe "calls objects_to_update" do
    let(:qbe_noninventory_product) { JSON.parse(File.read('spec/qbwc/response/generic_product_fixtures/product_from_qbe.json')) }
    let(:expected_object) {
      {
        object_type: 'noninventoryproduct',
        object_ref: "test-product",
        product_id: "test-product",
        list_id: "80001019-2039019",
        edit_sequence: "190aMNia90jmdk"
      }
    }
    
    describe "calls objects_to_update with one product returned" do
      it "has no parent product names and outputs just the product name" do
        noninventory_rs = QBWC::Response::ItemNonInventoryQueryRs.new([qbe_noninventory_product])
        output = noninventory_rs.send(:objects_to_update).first.with_indifferent_access

        expect(output).to eq(expected_object.with_indifferent_access)
      end

      it "has one parent product name as an object and outputs the parent name + : + product name" do
        expected_object[:object_ref] = "Parent NonInventory:test-product"
        qbe_noninventory_product["ParentRef"] = {
          "FullName" => "Parent NonInventory"
        }
        
        noninventory_rs = QBWC::Response::ItemNonInventoryQueryRs.new([qbe_noninventory_product])
        output = noninventory_rs.send(:objects_to_update).first.with_indifferent_access

        expect(output).to eq(expected_object.with_indifferent_access)
      end

      it "has one parent product name as an array and outputs the parent name + : + product name" do
        expected_object[:object_ref] = "Parent NonInventory:test-product"
        qbe_noninventory_product["ParentRef"] = [{
          "FullName" => "Parent NonInventory"
        }]
        
        noninventory_rs = QBWC::Response::ItemNonInventoryQueryRs.new([qbe_noninventory_product])
        output = noninventory_rs.send(:objects_to_update).first.with_indifferent_access

        expect(output).to eq(expected_object.with_indifferent_access)
      end

      it "has two parent product names as an object and outputs the parent names and product name correctly" do
        expected_object[:object_ref] = "Super Parent NonInventory:Parent NonInventory:test-product"
        qbe_noninventory_product["ParentRef"] = {
          "FullName" => "Super Parent NonInventory:Parent NonInventory"
        }
        
        noninventory_rs = QBWC::Response::ItemNonInventoryQueryRs.new([qbe_noninventory_product])
        output = noninventory_rs.send(:objects_to_update).first.with_indifferent_access

        expect(output).to eq(expected_object.with_indifferent_access)
      end

      it "has two parent product names as an array and outputs the parent names and product name correctly" do
        expected_object[:object_ref] = "Super Parent NonInventory:Parent NonInventory:test-product"
        qbe_noninventory_product["ParentRef"] = [
          {"FullName" => "Super Parent NonInventory"},
          {"FullName" => "Parent NonInventory"}
        ]
        
        noninventory_rs = QBWC::Response::ItemNonInventoryQueryRs.new([qbe_noninventory_product])
        output = noninventory_rs.send(:objects_to_update).first.with_indifferent_access

        expect(output).to eq(expected_object.with_indifferent_access)
      end
    end
  end
end