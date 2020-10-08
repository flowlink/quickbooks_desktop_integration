require 'rspec'
require 'json'
require 'qbwc/request/invoices'

RSpec.describe QBWC::Request::Invoices do
  let(:invoice) { JSON.parse(File.read('spec/qbwc/request/invoice_fixtures/invoice_from_flowlink.json')) }
  let(:credit_memo_one) { JSON.parse(File.read('spec/qbwc/request/invoice_fixtures/credit_memo_one.json')) }
  let(:credit_memo_two) { JSON.parse(File.read('spec/qbwc/request/invoice_fixtures/credit_memo_two.json')) }

  describe '#transaction_already_occured?' do
    describe 'given a non matching pair' do
      it 'returns false' do
        output = QBWC::Request::Invoices.transaction_already_occured?(invoice,credit_memo_one)
        expect(output).to be false
      end
    end

    describe 'given a matching pair' do
      it 'returns true' do
        output = QBWC::Request::Invoices.transaction_already_occured?(invoice,credit_memo_two)
        expect(output).to be true
      end
    end
  end

  describe '#credit_list' do
    it 'calls credit_list and outputs the right data' do
      output = QBWC::Request::Invoices.credit_list(invoice)
      expect(output).to include(credit_memo_one['qbe_id'])
      expect(output).not_to include(credit_memo_two['qbe_id'])
    end
  end
end