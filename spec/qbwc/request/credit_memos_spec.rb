require 'rspec'
require 'json'
require 'active_support/core_ext/hash/indifferent_access'
require 'qbwc/request/creditmemos'

RSpec.describe QBWC::Request::Creditmemos do
  let(:flowlink_memo) { JSON.parse(File.read('spec/qbwc/request/creditmemo_fixtures/memo_from_flowlink.json')) }
  let(:addr) { {
    address1: "123 Main St",
    address2: "Suite 200",
    address3: "XYZ",
    city: "Pittsburgh",
    state: "PA",
    zipcode: "12345",
    country: "USA",
    note: "Hiya"
  } }
  let(:config) { {} }
  let(:is_mod) { rand(2) == 0 }
  let(:address_name) { "BillAddress" }

  context '#address' do

    describe 'with a nil address' do
      let(:addr) { nil }

      it 'returns an empty string' do
        expect(QBWC::Request::Creditmemos.send(:address, addr, config, is_mod, address_name)).to eq("")
      end
    end

    describe 'with an address that is an empty object' do
      let(:addr) { {} }

      it 'returns a self closing xml node for BillAddress' do
        expect(QBWC::Request::Creditmemos.send(:address, addr, config, is_mod, address_name)).to eq("<BillAddress />")
      end

      it 'returns a self closing xml node for BillAddress' do
        expect(QBWC::Request::Creditmemos.send(:address, addr, config, is_mod, 'ShipAddress')).to eq("<ShipAddress />")
      end

      it 'returns a self closing xml node for iCanDoWhatIWant' do
        expect(QBWC::Request::Creditmemos.send(:address, addr, config, is_mod, 'iCanDoWhatIWant')).to eq("<iCanDoWhatIWant />")
      end
    end

    describe 'given a real address' do
      it 'returns address information' do
        output = QBWC::Request::Creditmemos.send(:address, addr, config, is_mod, address_name)
        expect(output).to include "<BillAddress>"
        expect(output).to include "123 Main St"
        expect(output).to include "Suite 200"
        expect(output).to include "XYZ"
        expect(output).to include "Pittsburgh"
        expect(output).to include "PA"
        expect(output).to include "12345"
        expect(output).to include "USA"
        expect(output).to include "Hiya"
        expect(output).to include "</BillAddress>"
      end
    end
  end

  context 'add_xml_to_send' do
    let(:memo) { QBWC::Request::Creditmemos.add_xml_to_send(flowlink_memo, {}, 12345, {}) }

    it 'returns customer info' do
      expect(memo).to include 'CustomerRef'
      expect(memo).to include 'ABC Test'
    end

    it 'returns credit memo line info' do
      expect(memo).to include 'CreditMemoLineAdd'
      expect(memo).to include 'ItemRef'
      expect(memo).to include 'cold-brew'
      expect(memo).to include 'Desc'
      expect(memo).to include 'Cold brew'
      expect(memo).to include 'Quantity'
      expect(memo).to include '2'
      expect(memo).to include 'Rate'
      expect(memo).to include '0.00'
    end

    it 'does return the externalGUID' do
      expect(memo).to include '{9ADB6B68-2DDB-4FEA-9271-AE8725F4DBAD}'
    end

  end

  context 'update_xml_to_send' do
    let(:memo) { QBWC::Request::Creditmemos.update_xml_to_send(flowlink_memo, {}, 12345, {}) }

    it 'returns txn and edit sequence information' do
      expect(memo).to include 'TxnID'
      expect(memo).to include 'list-1234'
      expect(memo).to include 'EditSequence'
      expect(memo).to include '123456789'
    end

    it 'returns credit memo line info' do
      expect(memo).to include 'CreditMemoLineMod'
      expect(memo).to include 'ItemRef'
      expect(memo).to include 'cold-brew'
      expect(memo).to include 'Desc'
      expect(memo).to include 'Cold brew'
      expect(memo).to include 'Quantity'
      expect(memo).to include '2'
      expect(memo).to include 'Rate'
      expect(memo).to include '0.00'
    end

    it 'does not return the externalGUID' do
      expect(memo).not_to include '{9ADB6B68-2DDB-4FEA-9271-AE8725F4DBAD}'
    end
  end
end
