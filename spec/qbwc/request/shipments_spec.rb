require 'spec_helper'

module QBWC
  module Request
    describe Shipments do
      subject { described_class }

      it "builds request xml" do
        subject.add_xml_to_send Factory.shipment['shipment'], {}, 123
      end
    end
  end
end
