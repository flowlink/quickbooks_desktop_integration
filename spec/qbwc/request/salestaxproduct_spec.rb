require 'rspec'
require 'json'
require "active_support/core_ext/hash/indifferent_access"
require 'qbwc/request/salestaxproducts'
require 'qbwc/request/salestaxproduct_fixtures/add_update_search_xml_fixtures'

RSpec.describe QBWC::Request::Salestaxproducts do
  describe "product_identifier method" do
    let(:salestaxproduct) {
      {
        "product_id" => "product ABC",
        "sku" => "product 123",
        "id" => "product XYZ"
      }
    }
    it "is given a product_id field and uses this field" do
      identifier_value = QBWC::Request::Salestaxproducts.send(:product_identifier, salestaxproduct)
      expect(identifier_value).to eq("product ABC")
    end

    it "is has no product_id field, but has sku and uses this field" do
      salestaxproduct.delete("product_id")
      identifier_value = QBWC::Request::Salestaxproducts.send(:product_identifier, salestaxproduct)
      expect(identifier_value).to eq("product 123")
    end

    it "is has no product_id or sku field, but has id and uses this field" do
      salestaxproduct.delete("sku")
      salestaxproduct.delete("product_id")
      identifier_value = QBWC::Request::Salestaxproducts.send(:product_identifier, salestaxproduct)
      expect(identifier_value).to eq("product XYZ")
    end
    
    it "is has no product_id, sku, or id field so nil is returned" do
      salestaxproduct.delete("sku")
      salestaxproduct.delete("product_id")
      salestaxproduct.delete("id")
      identifier_value = QBWC::Request::Salestaxproducts.send(:product_identifier, salestaxproduct)
      expect(identifier_value).to eq(nil)
    end
  end

  describe "search xml" do
    let(:flowlink_product) { JSON.parse(File.read('spec/qbwc/request/product_fixtures/invproduct_from_flowlink.json')) }
    it "has list_id and calls search_xml_by_id" do
      flowlink_product[:list_id] = "test salestax listid"

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
      product = QBWC::Request::Salestaxproducts.search_xml_by_id("test salestax listid", 12345)
      expect(product.gsub(/\s+/, "")).to eq(qbe_salestaxproduct_search_id.gsub(/\s+/, ""))
    end
    it "calls search_xml_by_name and matches expected xml output" do
      product = QBWC::Request::Salestaxproducts.search_xml_by_name("My Awesome Product", 12345)
      expect(product.gsub(/\s+/, "")).to eq(qbe_salestaxproduct_search_name.gsub(/\s+/, ""))
    end
  end

  describe "builds xml for adding or updating" do
    let(:flowlink_product) { JSON.parse(File.read('spec/qbwc/request/salestaxproduct_fixtures/salestaxproduct_from_flowlink.json')) }
    config = {
      class_name: "Class1:Class2",
      quickbooks_sales_tax_return_line_name: "Sales Tax Return Line Name"
    }
    
    it "matches expected xml when calling add_xml_to_send" do
      product = QBWC::Request::Salestaxproducts.add_xml_to_send(flowlink_product, nil, 12345, config)
      expect(product.gsub(/\s+/, "")).to eq(add_xml_salestaxproduct.gsub(/\s+/, ""))
    end

    it "matches expected xml when calling update_xml_to_send" do
      flowlink_product["list_id"] = "test salestax listid"
      flowlink_product["edit_sequence"] = "19209j3od-d9292"

      product = QBWC::Request::Salestaxproducts.update_xml_to_send(flowlink_product, nil, 12345, config)
      expect(product.gsub(/\s+/, "")).to eq(update_xml_salestaxproduct.gsub(/\s+/, ""))
    end

    it "it matches expected xml when updating salestax product with active field" do
      flowlink_product["list_id"] = "test salestax listid"
      flowlink_product["edit_sequence"] = "19209j3od-d9292"
      flowlink_product["active"] = true
      
      product = QBWC::Request::Salestaxproducts.update_xml_to_send(flowlink_product, nil, 12345, config)
      expect(product.gsub(/\s+/, "")).to eq(update_xml_with_active_field_salestaxproduct.gsub(/\s+/, ""))
    end
  end
end
