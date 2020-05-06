require 'rspec'
require 'json'
require "active_support/core_ext/hash/indifferent_access"
require 'qbwc/request/noninventoryproducts'
require 'qbwc/request/noninventoryproduct_fixtures/add_update_search_xml_fixtures'

RSpec.describe QBWC::Request::Noninventoryproducts do
  describe "product_identifier method" do
    let(:noninventoryproduct) {
      {
        "product_id" => "product ABC",
        "sku" => "product 123",
        "id" => "product XYZ"
      }
    }
    it "is given a product_id field and uses this field" do
      identifier_value = QBWC::Request::Noninventoryproducts.send(:product_identifier, noninventoryproduct)
      expect(identifier_value).to eq("product ABC")
    end

    it "is has no product_id field, but has sku and uses this field" do
      noninventoryproduct.delete("product_id")
      identifier_value = QBWC::Request::Noninventoryproducts.send(:product_identifier, noninventoryproduct)
      expect(identifier_value).to eq("product 123")
    end

    it "is has no product_id or sku field, but has id and uses this field" do
      noninventoryproduct.delete("sku")
      noninventoryproduct.delete("product_id")
      identifier_value = QBWC::Request::Noninventoryproducts.send(:product_identifier, noninventoryproduct)
      expect(identifier_value).to eq("product XYZ")
    end
    
    it "is has no product_id, sku, or id field so nil is returned" do
      noninventoryproduct.delete("sku")
      noninventoryproduct.delete("product_id")
      noninventoryproduct.delete("id")
      identifier_value = QBWC::Request::Noninventoryproducts.send(:product_identifier, noninventoryproduct)
      expect(identifier_value).to eq(nil)
    end
  end

  describe "search xml" do
    let(:flowlink_product) { JSON.parse(File.read('spec/qbwc/request/noninventoryproduct_fixtures/noninvproduct_from_flowlink.json')) }
    it "has list_id and calls search_xml_by_id" do
      flowlink_product[:list_id] = "test noninv listid"
      # Call search_xml method with flowlink_product
      pending("expect the search_xml_by_id method to have been called")
      pending("expect the search_xml_by_name method to NOT have been called")
      this_should_not_get_executed
    end
    it "does not have list_id and calls search_xml_by_name" do
      # Call search_xml method with flowlink_product
      pending("expect the search_xml_by_name method to have been called")
      pending("expect the search_xml_by_id method to NOT have been called")
      this_should_not_get_executed
    end
    it "calls search_xml_by_id and matches expected xml output" do
      product = QBWC::Request::Noninventoryproducts.search_xml_by_id("test noninv listid", 12345)
      expect(product.gsub(/\s+/, "")).to eq(qbe_noninventoryproduct_search_id.gsub(/\s+/, ""))
    end
    it "calls search_xml_by_name and matches expected xml output" do
      product = QBWC::Request::Noninventoryproducts.search_xml_by_name("My Awesome Product", 12345)
      expect(product.gsub(/\s+/, "")).to eq(qbe_noninventoryproduct_search_name.gsub(/\s+/, ""))
    end
  end

  describe "builds xml for adding or updating" do
    let(:flowlink_product) { JSON.parse(File.read('spec/qbwc/request/noninventoryproduct_fixtures/noninvproduct_from_flowlink.json')) }
    config = {
      class_name: "Class1:Class2",
      quickbooks_expense_account: "Expense Account"
    }
    
    it "matches expected xml when adding sales and purchase" do
      flowlink_product["sales_and_purchase"] = true

      product = QBWC::Request::Noninventoryproducts.add_xml_to_send(flowlink_product, nil, 12345, config)
      expect(product.gsub(/\s+/, "")).to eq(add_xml_sandp_noninventoryproduct.gsub(/\s+/, ""))
    end

    it "matches expected xml when adding sales or purchase with percent field" do
      flowlink_product["sales_or_purchase"] = true
      flowlink_product["price"] = nil

      product = QBWC::Request::Noninventoryproducts.add_xml_to_send(flowlink_product, nil, 12345, config)
      expect(product.gsub(/\s+/, "")).to eq(add_xml_sorp_with_percent_noninventoryproduct.gsub(/\s+/, ""))
    end

    it "matches expected xml when adding sales or purchase without percent field" do
      flowlink_product["sales_or_purchase"] = true

      product = QBWC::Request::Noninventoryproducts.add_xml_to_send(flowlink_product, nil, 12345, config)
      expect(product.gsub(/\s+/, "")).to eq(add_xml_sorp_without_percent_noninventoryproduct.gsub(/\s+/, ""))
    end

    it "matches expected xml when adding basic product (no sales_or_purchase and no sales_and_purchase)" do
      flowlink_product["sales_or_purchase"] = nil
      flowlink_product["sales_and_purchase"] = nil

      product = QBWC::Request::Noninventoryproducts.add_xml_to_send(flowlink_product, nil, 12345, config)
      expect(product.gsub(/\s+/, "")).to eq(add_xml_basic_noninventoryproduct.gsub(/\s+/, ""))
    end

    it "matches expected xml when adding basic product with both sales_or_purchase and sales_and_purchase fields set to true" do
      flowlink_product["sales_or_purchase"] = true
      flowlink_product["sales_and_purchase"] = true

      product = QBWC::Request::Noninventoryproducts.add_xml_to_send(flowlink_product, nil, 12345, config)
      expect(product.gsub(/\s+/, "")).to eq(add_xml_basic_noninventoryproduct.gsub(/\s+/, ""))
    end

    it "matches expected xml when updating sales and purchase" do
      flowlink_product["sales_and_purchase"] = true
      flowlink_product["list_id"] = "test noninv product"
      flowlink_product["edit_sequence"] = "19209j3od-d9292"

      product = QBWC::Request::Noninventoryproducts.update_xml_to_send(flowlink_product, nil, 12345, config)
      expect(product.gsub(/\s+/, "")).to eq(update_xml_sandp_noninventoryproduct.gsub(/\s+/, ""))
    end

    it "matches expected xml when updating sales or purchase with percent field" do
      flowlink_product["sales_or_purchase"] = true
      flowlink_product["list_id"] = "test noninv product"
      flowlink_product["edit_sequence"] = "19209j3od-d9292"
      flowlink_product["price"] = nil
      
      product = QBWC::Request::Noninventoryproducts.update_xml_to_send(flowlink_product, nil, 12345, config)
      expect(product.gsub(/\s+/, "")).to eq(update_xml_sorp_with_percent_noninventoryproduct.gsub(/\s+/, ""))
    end

    it "it matches expected xml when updating sales or purchase without percent field" do
      flowlink_product["sales_or_purchase"] = true
      flowlink_product["list_id"] = "test noninv product"
      flowlink_product["edit_sequence"] = "19209j3od-d9292"
      
      product = QBWC::Request::Noninventoryproducts.update_xml_to_send(flowlink_product, nil, 12345, config)
      expect(product.gsub(/\s+/, "")).to eq(update_xml_sorp_without_percent_noninventoryproduct.gsub(/\s+/, ""))
    end

    it "matches expected xml when updating basic product (no sales_or_purchase and no sales_and_purchase)" do
      flowlink_product["sales_or_purchase"] = nil
      flowlink_product["sales_and_purchase"] = nil
      flowlink_product["list_id"] = "test noninv product"
      flowlink_product["edit_sequence"] = "19209j3od-d9292"

      product = QBWC::Request::Noninventoryproducts.update_xml_to_send(flowlink_product, nil, 12345, config)
      expect(product.gsub(/\s+/, "")).to eq(update_xml_basic_noninventoryproduct.gsub(/\s+/, ""))
    end

    it "matches expected xml when updating basic product with both sales_or_purchase and sales_and_purchase fields set to true" do
      flowlink_product["sales_or_purchase"] = true
      flowlink_product["sales_and_purchase"] = true
      flowlink_product["list_id"] = "test noninv product"
      flowlink_product["edit_sequence"] = "19209j3od-d9292"

      product = QBWC::Request::Noninventoryproducts.update_xml_to_send(flowlink_product, nil, 12345, config)
      expect(product.gsub(/\s+/, "")).to eq(update_xml_sandp_noninventoryproduct.gsub(/\s+/, ""))
    end

    it "it matches expected xml when updating noninventory product with active field" do
      flowlink_product["list_id"] = "test noninv product"
      flowlink_product["edit_sequence"] = "19209j3od-d9292"
      flowlink_product["active"] = true
      
      product = QBWC::Request::Noninventoryproducts.update_xml_to_send(flowlink_product, nil, 12345, config)
      expect(product.gsub(/\s+/, "")).to eq(update_xml_with_active_field_noninventoryproduct.gsub(/\s+/, ""))
    end
  end
end
