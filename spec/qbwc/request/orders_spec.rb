require 'spec_helper'

module QBWC
  module Request
    describe Orders do
      before do
        allow(Persistence::Session).to receive(:save).and_return('82bfb8e5-99e3-41c9-a4cc-19a0001b6ecf')
      end

      subject { described_class }

      it 'builds xml request from orders' do
        orders = Factory.orders['orders']
        orders.first['line_items'].first['quantity'] = 2
        VCR.use_cassette 'requests/insert_update_orders' do
          xml = subject.generate_request_insert_update orders
          expect(xml).to match /SalesOrderAdd/
          expect(xml).to match /SalesOrderLineAdd/
          expect(xml).to match /100.00/
          expect(xml).to match /\<Quantity\>2\<\/Quantity\>/
        end
      end

      it 'builds xml request from orders with zero quantity' do
        orders = Factory.orders['orders']
        orders.first['line_items'].first['quantity'] = 0

        xml = subject.generate_request_insert_update orders
        expect(xml).to match /SalesOrderAdd/
        expect(xml).to match /SalesOrderLineAdd/
        expect(xml).to match /100.00/
        expect(xml.match(/Quantity/)).to be_nil
      end

      it 'builds xml request sanitizing address fields' do
        orders = Factory.orders['orders']
        order = orders.first
        order['billing_address']['address1'] << '21 1ª6'
        order['billing_address']['address2'] << '21 1ª6'
        order['billing_address']['city'] << '21 1ª6'
        order['billing_address']['state'] << '21 1ª6'
        order['billing_address']['zipcode'] << '21 1ª6'
        order['billing_address']['country'] << '21 1ª6'
        order['shipping_address']['address1'] << '21 1ª6'
        order['shipping_address']['address2'] << '21 1ª6'
        order['shipping_address']['city'] << '21 1ª6'
        order['shipping_address']['state'] << '21 1ª6'
        order['shipping_address']['zipcode'] << '21 1ª6'
        order['shipping_address']['country'] << '21 1ª6'

        xml = subject.generate_request_insert_update orders
        expect(xml).to match /SalesOrderAdd/
        expect(xml).to match /SalesOrderLineAdd/
        expect(xml.match(/ª/)).to be_nil
      end

      context 'optional fields' do
        it 'builds PONumber request from purchase_order_number' do
          orders = Factory.orders['orders']
          orders.first['purchase_order_number'] = '824'

          VCR.use_cassette 'requests/insert_update_orders' do
            xml = subject.generate_request_insert_update orders
            expect(xml).to match /PONumber/
            expect(xml).to match /824/
          end
        end

        it 'builds ShipDate request from ship_date' do
          orders = Factory.orders['orders']
          orders.first['ship_date'] = '06-09-2020'

          VCR.use_cassette 'requests/insert_update_orders' do
            xml = subject.generate_request_insert_update orders
            expect(xml).to match /ShipDate/
            expect(xml).to match /06-09-2020/
          end
        end
      end
    end
  end
end
