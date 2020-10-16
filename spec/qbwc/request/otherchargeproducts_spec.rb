require 'spec_helper'
require 'rspec'
require 'json'
require "active_support/core_ext/hash/indifferent_access"
require 'qbwc/request/otherchargeproducts'

module QBWC
  module Request
    describe Otherchargeproducts do
      before(:each) do
        Aws.config[:stub_responses] = true
      end
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

      context '#generate_request_insert_update' do
        it 'returns an empty string when no records' do
          records = []
          params = {'quickbooks_since' => '2020-01-10T08:24:55Z', 'quickbooks_max_returned' => '1000'}
          xml = subject.generate_request_insert_update(records, params)
          expect(xml).to match ''
        end

        it 'returns an xml to add the product' do
          records = [{
            'id' => 123,
            'product_id' => 'product'
          }]
          params = {'quickbooks_since' => '2020-01-10T08:24:55Z', 'quickbooks_max_returned' => '1000'}
          xml = subject.generate_request_insert_update(records, params)
          expect(xml).to match 'ItemOtherChargeAdd'
        end

        context 'updating the product' do
          let(:records) {
            [{
              'id' => 123,
              'product_id' => 'product',
              'list_id' => 'list',
            }]
          }
          let(:params) {
            {'quickbooks_since' => '2020-01-10T08:24:55Z', 'quickbooks_max_returned' => '1000'}
          }
          let(:active_records) {
            [{
              'id' => 123,
              'product_id' => 'product',
              'list_id' => 'list',
              'active' => true
            }]
          }

          it 'returns an xml as a mod' do
            xml = subject.generate_request_insert_update(records, params)
            expect(xml).to match 'ItemOtherChargeMod'
          end

          it 'returns an xml with an edit sequence and given list id' do
            xml = subject.generate_request_insert_update(records, params)
            expect(xml).to match 'ListID'
            expect(xml).to match records.first['list_id']
            expect(xml).to match 'EditSequence'
          end

          it 'active products return IsActive' do
            xml = subject.generate_request_insert_update(active_records, params)
            expect(xml).to match 'IsActive'
          end
        end

      end

      context '#product_xml' do
        let(:flowlink_product) { JSON.parse(File.read('spec/qbwc/request/otherchargeproduct_fixtures/otherchargeproduct_from_flowlink.json')) }
        let(:config) {
          {
            class_name: "Class1:Class2",
            quickbooks_expense_account: "Expense Account"
          }
        }

        context 'add xml' do
          it 'returns the id in the xml' do
            xml = QBWC::Request::Otherchargeproducts.send(:product_xml, flowlink_product, config, false)
            expect(xml).to match(flowlink_product['id'])
          end

          it 'returns the XML for all GENERAL_MAPPING names' do
            xml = QBWC::Request::Otherchargeproducts.send(:product_xml, flowlink_product, config, false)
            QBWC::Request::Otherchargeproducts::GENERAL_MAPPING.each do |mapping|
              expect(xml).to match(mapping[:qbe_name])
              expect(xml).to match(flowlink_product[mapping[:flowlink_name]].to_s)
            end
          end

          it 'returns the XML for all EXTERNAL_GUID_MAP names' do
            xml = QBWC::Request::Otherchargeproducts.send(:product_xml, flowlink_product, config, false)
            QBWC::Request::Otherchargeproducts::EXTERNAL_GUID_MAP.each do |mapping|
              expect(xml).to match(mapping[:qbe_name])
              expect(xml).to match(flowlink_product[mapping[:flowlink_name]].to_s)
            end
          end

          it 'returns the XML for add related SALES_OR_PURCHASE_MAP names' do
            flowlink_product["sales_or_purchase"] = true
            xml = QBWC::Request::Otherchargeproducts.send(:product_xml, flowlink_product, config, false)
            QBWC::Request::Otherchargeproducts::SALES_OR_PURCHASE_MAP.each do |mapping|
              next if mapping[:mod_only] == true
              # Price percent is nil if a price is given
              next if mapping[:flowlink_name] == 'price_percent' && flowlink_product['price']

              expect(xml).to match(mapping[:qbe_name])
              expect(xml).to match(flowlink_product[mapping[:flowlink_name]].to_s)
            end
          end

          it 'returns the XML for add related SALES_AND_PURCHASE_MAP names' do
            flowlink_product["sales_and_purchase"] = true
            xml = QBWC::Request::Otherchargeproducts.send(:product_xml, flowlink_product, config, false)
            QBWC::Request::Otherchargeproducts::SALES_AND_PURCHASE_MAP.each do |mapping|
              next if mapping[:mod_only] == true
              # Price percent is nil if a price is given
              next if mapping[:flowlink_name] == 'price_percent' && flowlink_product['price']

              expect(xml).to match(mapping[:qbe_name])
              expect(xml).to match(flowlink_product[mapping[:flowlink_name]].to_s)
            end
          end
        end

        context 'mod xml' do
          it 'returns the id in the xml' do
            xml = QBWC::Request::Otherchargeproducts.send(:product_xml, flowlink_product, config, true)
            expect(xml).to match(flowlink_product['id'])
          end

          it 'returns the XML for all GENERAL_MAPPING names' do
            xml = QBWC::Request::Otherchargeproducts.send(:product_xml, flowlink_product, config, true)
            QBWC::Request::Otherchargeproducts::GENERAL_MAPPING.each do |mapping|
              expect(xml).to match(mapping[:qbe_name])
              expect(xml).to match(flowlink_product[mapping[:flowlink_name]].to_s)
            end
          end

          it 'returns the XML for all SALES_OR_PURCHASE_MAP names' do
            flowlink_product["sales_or_purchase"] = true
            xml = QBWC::Request::Otherchargeproducts.send(:product_xml, flowlink_product, config, true)
            QBWC::Request::Otherchargeproducts::SALES_OR_PURCHASE_MAP.each do |mapping|

              # Price percent is nil if a price is given
              next if mapping[:flowlink_name] == 'price_percent' && flowlink_product['price']

              expect(xml).to match(mapping[:qbe_name])
              expect(xml).to match(flowlink_product[mapping[:flowlink_name]].to_s)
            end
          end

          it 'returns the XML for add related SALES_AND_PURCHASE_MAP names' do
            flowlink_product["sales_and_purchase"] = true
            xml = QBWC::Request::Otherchargeproducts.send(:product_xml, flowlink_product, config, true)
            QBWC::Request::Otherchargeproducts::SALES_AND_PURCHASE_MAP.each do |mapping|
              next if mapping[:mod_only] == false
              # Price percent is nil if a price is given
              next if mapping[:flowlink_name] == 'price_percent' && flowlink_product['price']

              expect(xml).to match(mapping[:qbe_name])
              expect(xml).to match(flowlink_product[mapping[:flowlink_name]].to_s)
            end
          end
        end


      end

    end
  end
end
