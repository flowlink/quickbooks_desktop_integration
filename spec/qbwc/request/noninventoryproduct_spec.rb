require 'rspec'
require 'json'
require "active_support/core_ext/hash/indifferent_access"
require 'qbwc/request/noninventoryproducts'
require 'qbwc/request/noninventoryproduct_fixtures/add_update_search_xml_fixtures'

RSpec.describe QBWC::Request::Noninventoryproducts do
  describe "builds xml for adding or updating" do
    let(:flowlink_product) { JSON.parse(File.read('spec/qbwc/request/noninventoryproduct_fixtures/noninvproduct_from_flowlink.json')) }
    config = {
      class_name: "Class1:Class2",
      quickbooks_expense_account: "Expense Account"
    }
    
    it "it matches expected xml when adding sales and purchase" do
      product = QBWC::Request::Noninventoryproducts.add_xml_to_send(flowlink_product, nil, 12345, config)
      expect(product.gsub(/\s+/, "")).to eq(add_xml_sandp.gsub(/\s+/, ""))
    end

    it "it matches expected xml when adding sales or purchase with percent field" do
      flowlink_product["sale_or_purchase"] = true
      flowlink_product["price"] = nil

      product = QBWC::Request::Noninventoryproducts.add_xml_to_send(flowlink_product, nil, 12345, config)
      expect(product.gsub(/\s+/, "")).to eq(add_xml_sorp_with_percent.gsub(/\s+/, ""))
    end

    it "it matches expected xml when adding sales or purchase without percent field" do
      flowlink_product["sale_or_purchase"] = true

      product = QBWC::Request::Noninventoryproducts.add_xml_to_send(flowlink_product, nil, 12345, config)
      expect(product.gsub(/\s+/, "")).to eq(add_xml_sorp_without_percent.gsub(/\s+/, ""))
    end
    
    it "it matches expected xml when updating sales and purchase" do
      flowlink_product["list_id"] = "test noninv product"
      flowlink_product["edit_sequence"] = "19209j3od-d9292"

      product = QBWC::Request::Noninventoryproducts.update_xml_to_send(flowlink_product, nil, 12345, config)
      expect(product.gsub(/\s+/, "")).to eq(update_xml_sandp.gsub(/\s+/, ""))
    end

    it "it matches expected xml when updating sales or purchase with percent field" do
      flowlink_product["sale_or_purchase"] = true
      flowlink_product["list_id"] = "test noninv product"
      flowlink_product["edit_sequence"] = "19209j3od-d9292"
      flowlink_product["price"] = nil
      
      product = QBWC::Request::Noninventoryproducts.update_xml_to_send(flowlink_product, nil, 12345, config)
      expect(product.gsub(/\s+/, "")).to eq(update_xml_sorp_with_percent.gsub(/\s+/, ""))
    end

    it "it matches expected xml when updating sales or purchase without percent field" do
      flowlink_product["sale_or_purchase"] = true
      flowlink_product["list_id"] = "test noninv product"
      flowlink_product["edit_sequence"] = "19209j3od-d9292"
      
      product = QBWC::Request::Noninventoryproducts.update_xml_to_send(flowlink_product, nil, 12345, config)
      expect(product.gsub(/\s+/, "")).to eq(update_xml_sorp_without_percent.gsub(/\s+/, ""))
    end
  end
end
