require 'rspec'
require 'json'
require 'active_support/core_ext/hash/indifferent_access'
require 'qbwc/request/creditmemos'

RSpec.describe QBWC::Request::Creditmemos do
  let(:flowlink_memo) { JSON.parse(File.read('spec/qbwc/request/creditmemo_fixtures/memo_from_flowlink.json')) }

  context 'add_xml_to_send' do
    let(:memo) { QBWC::Request::Creditmemos.add_xml_to_send(flowlink_memo, {}, 12345, {}) }

    it 'returns customer info' do
      expect(memo).to include 'CustomerRef'
      expect(memo).to include 'ABC Test'
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
  end
end
