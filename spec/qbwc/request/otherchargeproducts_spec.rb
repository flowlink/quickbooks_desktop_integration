require 'spec_helper'
require 'rspec'
require 'json'
require "active_support/core_ext/hash/indifferent_access"
require 'qbwc/request/otherchargeproducts'

module QBWC
  module Request
    describe Otherchargeproducts do
      subject { described_class }

      context '#polling_others_items_xml' do
        it 'returns an empty string' do
          params = {'quickbooks_since' => '2020-01-10T08:24:55Z', 'quickbooks_max_returned' => '1000'}
          config = {}
          xml = subject.polling_others_items_xml(params, config)
          expect(xml).to match ''
        end
      end

      context '#polling_current_items_xml' do

        it 'returns expect xml type' do
          params = {'quickbooks_since' => '2020-01-10T08:24:55Z'}
          config = {}
          xml = subject.polling_current_items_xml(params, config)
          expect(xml).to match 'ItemOtherChargeQueryRq'
        end

        it 'returns default 50 max items returned' do
          params = {'quickbooks_since' => '2020-01-10T08:24:55Z'}
          config = {}
          xml = subject.polling_current_items_xml(params, config)
          expect(xml).to match '50'
        end

        it 'parses quickbooks_since and return matching timestamp' do
          params = {'quickbooks_since' => '2020-01-10T08:24:55Z'}
          config = {}
          xml = subject.polling_current_items_xml(params, config)
          expect(xml).to match '2020-01-10T00:24:55-08:00'
        end

        it 'sets a new max returned' do
          params = {'quickbooks_since' => '2020-01-10T08:24:55Z', 'quickbooks_max_returned' => '1000'}
          config = {}
          xml = subject.polling_current_items_xml(params, config)
          expect(xml).to match 'ItemOtherChargeQueryRq'
          expect(xml).to match params['quickbooks_max_returned']
        end
      end

      context '#generate_request_queries' do
        it 'returns an empty string when no records' do
          records = []
          params = {'quickbooks_since' => '2020-01-10T08:24:55Z', 'quickbooks_max_returned' => '1000'}
          xml = subject.generate_request_queries(records, params)
          expect(xml).to match ''
        end

        it 'returns a query searching by name' do
          records = [{
            'id' => 123,
            'product_id' => 'product'
          }]
          params = {'quickbooks_since' => '2020-01-10T08:24:55Z', 'quickbooks_max_returned' => '1000'}
          xml = subject.generate_request_queries(records, params)
          expect(xml).to match 'NameRangeFilter'
          expect(xml).to match records.first['product_id']
        end

        it 'returns a query searching by list id' do
          records = [{
            'id' => 123,
            'product_id' => 'product',
            'list_id' => 'list'
          }]
          params = {'quickbooks_since' => '2020-01-10T08:24:55Z', 'quickbooks_max_returned' => '1000'}
          xml = subject.generate_request_queries(records, params)
          expect(xml).to match 'ListID'
          expect(xml).to match records.first['list_id']
        end
      end


    end
  end
end
