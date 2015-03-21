require 'spec_helper'

module QBWC
  module Request
    describe Shipments do
      before do
        allow_any_instance_of(Persistence::Object).to receive(:save_session).and_return("82bfb8e5-99e3-41c9-a4cc-19a0001b6ecf")
      end

      subject { described_class }

      it "builds request xml" do
        subject.add_xml_to_send Factory.shipment['shipment'], {}, 123
      end

      it "builds xml request sanitizing address fields" do
        shipments = Factory.shipments['shipments']
        shipment = shipments.first
        shipment['billing_address']['address1'] << '21 1ª6'
        shipment['billing_address']['address2'] << '21 1ª6'
        shipment['billing_address']['city'] << '21 1ª6'
        shipment['billing_address']['state'] << '21 1ª6'
        shipment['billing_address']['zipcode'] << '21 1ª6'
        shipment['billing_address']['country'] << '21 1ª6'
        shipment['shipping_address']['address1'] << '21 1ª6'
        shipment['shipping_address']['address2'] << '21 1ª6'
        shipment['shipping_address']['city'] << '21 1ª6'
        shipment['shipping_address']['state'] << '21 1ª6'
        shipment['shipping_address']['zipcode'] << '21 1ª6'
        shipment['shipping_address']['country'] << '21 1ª6'


        xml = subject.generate_request_insert_update shipments
        expect(xml).to match /InvoiceAdd/
        expect(xml).to match /InvoiceLineAdd/
        expect(xml.match(/ª/)).to be_nil
      end

    end
  end
end
