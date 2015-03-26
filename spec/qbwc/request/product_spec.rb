require 'spec_helper'

module QBWC
  module Request
    describe Products do
      subject { described_class }
      let(:product_insert) { [Factory.products[:products].first] }
      let(:product_update) { [product_insert.first.merge({:list_id=>'1234567'})] }

      before do
        allow(Persistence::Session).to receive(:save).and_return("1f8d3ff5-6f6c-43d6-a084-0ac95e2e29ad")
      end

      it "builds insert requests" do
        VCR.use_cassette "requests/insert_products" do
          request = subject.generate_request_insert_update(product_insert)
          expect(request).to match(/ItemInventoryAddRq/)
        end
      end

      it "builds update requests" do
        VCR.use_cassette "requests/update_products" do
          request = subject.generate_request_insert_update(product_update)
          expect(request).to match(/ItemInventoryModRq/)
        end
      end

      it "parses timestamp and return request xml" do
        time = Time.now.utc.to_s
        xml = subject.polling_current_items_xml(time, {})
        expect(xml).to match time.split.first
      end

    end
  end
end
