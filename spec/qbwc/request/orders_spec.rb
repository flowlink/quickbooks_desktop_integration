require 'spec_helper'

module QBWC
  module Request
    describe Orders do
      before do
        allow_any_instance_of(Persistence::Object).to receive(:save_session).and_return("82bfb8e5-99e3-41c9-a4cc-19a0001b6ecf")
      end

      subject { described_class }

      it "builds xml request from orders" do
        orders = Factory.orders['orders']
        VCR.use_cassette "requests/insert_update_orders" do
          xml = subject.generate_request_insert_update orders
          expect(xml).to match /SalesOrderAdd/
          expect(xml).to match /SalesOrderLineAdd/
          expect(xml).to match /100.00/
        end
      end
    end
  end
end
