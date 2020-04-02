require 'rspec'
require 'json'
require "active_support/core_ext/hash/indifferent_access"
require 'qbwc/response/item_non_inventory_query_rs'

RSpec.describe QBWC::Response::ItemNonInventoryQueryRs do
  let(:sandp_qbe_product) { JSON.parse(File.read('spec/qbwc/response/noninventory_product_fixtures/sales_and_purchase_prod_from_qbe.json')) }
  let(:sorp_qbe_product) { JSON.parse(File.read('spec/qbwc/response/noninventory_product_fixtures/sales_or_purchase_prod_from_qbe.json')) }
  
  let(:base_flowlink_product) { JSON.parse(File.read('spec/qbwc/response/noninventory_product_fixtures/noninventoryproduct_output.json')) }
  let(:fl_sales_and_purchase) { JSON.parse(File.read('spec/qbwc/response/noninventory_product_fixtures/sales_and_purchase_output.json')) }
  let(:fl_sales_or_purchase_with_percent) { JSON.parse(File.read('spec/qbwc/response/noninventory_product_fixtures/sales_or_purchase_with_percent_output.json')) }
  let(:fl_sales_or_purchase_without_percent) { JSON.parse(File.read('spec/qbwc/response/noninventory_product_fixtures/sales_or_purchase_no_percent_output.json')) }

  describe "calls products_to_flowlink" do
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
end