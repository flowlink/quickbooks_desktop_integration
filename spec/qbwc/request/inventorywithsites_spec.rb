require 'spec_helper'
require 'rspec'
require 'json'
require "active_support/core_ext/hash/indifferent_access"
require 'qbwc/request/inventorywithsites'

module QBWC
  module Request
    describe Inventorywithsites do
      before(:each) do
        Aws.config[:stub_responses] = true
      end
      subject { described_class }

      it 'parses quickbooks_site and return request xml' do
        params = {'quickbooks_since' => '2020-01-10T08:24:55Z'}
        config = {'quickbooks_site' => 'PHX'}
        xml = subject.polling_current_items_xml(params, config)
        puts xml.inspect
        expect(xml).to match 'ItemSitesQueryRq'
        expect(xml).to match config['quickbooks_site']
      end
    end
  end
end
