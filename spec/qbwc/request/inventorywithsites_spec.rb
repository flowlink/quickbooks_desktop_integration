require 'spec_helper'
require 'rspec'
require 'json'
require "active_support/core_ext/hash/indifferent_access"
require 'qbwc/request/inventorywithsites'

module QBWC
  module Request
    describe Inventorywithsites do
      subject { described_class }

      it 'parses quickbooks_site and return request xml' do
        params = {'quickbooks_since' => '2020-01-10T08:24:55Z', 'quickbooks_site' => 'PHX'}
        config = {}
        xml = subject.polling_current_items_xml(params, config)
        expect(xml).to match 'ItemSitesQueryRq'
        expect(xml).to match params['quickbooks_site']
      end
    end
  end
end
