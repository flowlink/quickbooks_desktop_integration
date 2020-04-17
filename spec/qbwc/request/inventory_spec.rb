require 'spec_helper'
require 'rspec'
require 'json'
require "active_support/core_ext/hash/indifferent_access"
require 'qbwc/request/inventories'

module QBWC
  module Request
    describe Inventories do
      subject { described_class }

      it 'parses timestamp and return request xml' do
        time = Time.now.utc.to_s
        params = {'quickbooks_since' => time}
        xml = subject.polling_current_items_xml(params, { 'quickbooks_inventory_site' => '1' })
        puts xml.inspect
        expect(xml).to match 'InventoryAdjustmentQueryRq'
      end
    end
  end
end
