require 'spec_helper'

module QBWC
  module Request
    describe Orders do
      subject { described_class }

      it "builds xml request from orders" do
        orders = Factory.orders['orders']
        xml = subject.generate_request_insert_update orders
        expect(xml).to match /SalesOrderAdd/
        expect(xml).to match /SalesOrderLineAdd/
      end
    end
  end
end
