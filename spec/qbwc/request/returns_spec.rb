require 'spec_helper'

module QBWC
  module Request
    describe Returns do
      before do
        allow(Persistence::Session).to receive(:save).and_return('82bfb8e5-99e3-41c9-a4cc-19a0001b6ecf')
      end

      subject { described_class }

      it 'builds xml inserts for returns' do
        returns = Factory.returns['returns']

        xml = subject.generate_request_insert_update returns
        expect(xml).to match(/SalesReceiptAddRq/)
        expect(xml).to match(/<RefNumber>RMA42671148<\/RefNumber>/)
        expect(xml).to match(/<FullName>CHECK<\/FullName>/)
        expect(xml).to match(/<FullName>SPREE-T-SHIRT<\/FullName>/)
        expect(xml).to match(/<Rate>19.99<\/Rate>/)
      end
    end
  end
end
