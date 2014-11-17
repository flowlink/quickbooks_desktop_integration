require 'spec_helper'

module QBWC
  module Request
    describe Products do
      subject { described_class }
      let(:product_insert) { [Factory.products[:products].first] }
      let(:product_update) { [product_insert.first.merge({:list_id=>'1234567'})] }

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
    end
  end
end
