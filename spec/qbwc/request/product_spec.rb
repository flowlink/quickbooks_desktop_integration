require 'spec_helper'
require 'rspec'
require 'json'
require "active_support/core_ext/hash/indifferent_access"
require 'qbwc/request/vendors'
require 'qbwc/request/product_fixtures/build_polling_from_config_fixtures'

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
        xml = subject.polling_current_items_xml(time, {})
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
end
