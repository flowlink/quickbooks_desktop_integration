require 'spec_helper'
require 'rspec'
require 'json'
require "active_support/core_ext/hash/indifferent_access"
require 'qbwc/request/vendors'
require 'qbwc/request/product_fixtures/build_polling_from_config_fixtures'
require 'qbwc/request/product_fixtures/add_update_search_xml_fixtures'

module QBWC
  module Request
    describe Products do
      subject { described_class }
      let(:product_insert) { [Factory.products[:products].first] }
      let(:product_update) { [product_insert.first.merge(list_id: '1234567')] }

      before do
        allow(Persistence::Session).to receive(:save).and_return('1f8d3ff5-6f6c-43d6-a084-0ac95e2e29ad')
      end

      it 'builds insert requests' do
        VCR.use_cassette 'requests/insert_products' do
          request = subject.generate_request_insert_update(product_insert)
          expect(request).to match(/ItemInventoryAddRq/)
        end
      end

      it 'builds update requests' do
        VCR.use_cassette 'requests/update_products' do
          request = subject.generate_request_insert_update(product_update)
          expect(request).to match(/ItemInventoryModRq/)
        end
      end

      it 'parses timestamp and return request xml' do
        time = Time.now.utc.to_s
        params = {"quickbooks_since" => time}
        xml = subject.polling_current_items_xml(params, {})
        expect(xml).to match time.split.first
      end
    end
  end
end

RSpec.describe QBWC::Request::Products do
  describe "calls build_polling_from_config_param" do
    config = {since: "2020-03-30 14:25:13 -0400"}.with_indifferent_access
    time = Time.parse(config[:since]).in_time_zone 'Pacific Time (US & Canada)'
    session_id = "12345903"
    
    it "it matches expected output when given full list of params" do
      config[:quickbooks_specify_products] = "[\"inventory\", \"assembly\", \"noninventory\", \"salestax\", \"service\", \"discount\"]"
      response = QBWC::Request::Products.send(:build_polling_from_config_param, config, session_id, time)
      expect(response.delete!("\n")).to eq(full_expected_output(time).delete!("\n"))
    end

    it "it matches expected output when given partial list of params" do
      config[:quickbooks_specify_products] = "[\"inventory\",  \"salestax\", \"service\"]"
      response = QBWC::Request::Products.send(:build_polling_from_config_param, config, session_id, time)
      expect(response.delete!("\n")).to eq(partial_expected_output(time).delete!("\n"))
    end

    it "it matches expected output when given 1 param" do
      config[:quickbooks_specify_products] = "[\"service\"]"
      response = QBWC::Request::Products.send(:build_polling_from_config_param, config, session_id, time)
      expect(response.delete!("\n")).to eq(one_expected_output(time).delete!("\n"))
    end
  end

  describe "builds xml for adding or updating" do
    let(:flowlink_product) { JSON.parse(File.read('spec/qbwc/request/product_fixtures/invproduct_from_flowlink.json')) }
    config = {quickbooks_cogs_account: "Cost of Goods"}

    it "it matches expected output" do
      product = QBWC::Request::Products.add_xml_to_send(flowlink_product, nil, 12345, config)
      expect(product.gsub(/\s+/, "")).to eq(add_xml.gsub(/\s+/, ""))
    end
    
    it "it matches expected output" do
      product = QBWC::Request::Products.update_xml_to_send(flowlink_product, nil, 12345, config)
      expect(product.gsub(/\s+/, "")).to eq(update_xml.gsub(/\s+/, ""))
    end
  end

  describe "search xml" do
    let(:flowlink_product) { JSON.parse(File.read('spec/qbwc/request/product_fixtures/invproduct_from_flowlink.json')) }
    it "has list_id and calls search_xml_by_id" do
      flowlink_product[:list_id] = "test product listid"

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
      product = QBWC::Request::Products.search_xml_by_id("test product listid", 12345)
      expect(product.gsub(/\s+/, "")).to eq(qbe_product_search_id.gsub(/\s+/, ""))
    end
    it "calls search_xml_by_name and matches expected xml output" do
      product = QBWC::Request::Products.search_xml_by_name("My Awesome Product", 12345)
      expect(product.gsub(/\s+/, "")).to eq(qbe_product_search_name.gsub(/\s+/, ""))
    end
  end
end
