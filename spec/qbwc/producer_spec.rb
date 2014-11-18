require 'spec_helper'

module QBWC
  describe Producer do
    before do
      allow_any_instance_of(Persistence::Object).to receive(:save_session).and_return("1f8d3ff5-6f6c-43d6-a084-0ac95e2e29ad")
    end

    it "build all request xml available per account" do
      subject = described_class.new connection_id: '54591b3a5869632afc090000'

      VCR.use_cassette "producer/454325352345" do
        xml = subject.build_available_actions_to_request
      end
    end

    it "builds request xml for polling flows" do
      subject = described_class.new connection_id: '54591b3a5869632afc090000'

      VCR.use_cassette "producer/543453253245353" do
        xml = subject.build_polling_request
        expect(xml).to match /ItemInventoryQueryRq/
      end
    end

    it "returns empty string if theres no polling config available" do
      subject = described_class.new connection_id: 'nonoNONONONONONOOOOOOO'

      VCR.use_cassette "producer/45435323452352352" do
        xml = subject.build_polling_request
        expect(xml).to eq ''
      end
    end

    # how about not support update orders instead?!!
    #
    # it "builds request xml for sales order query" do
    #   subject = described_class.new connection_id: '54591b3a5869632afc090000'

    #   VCR.use_cassette "producer/452435543524532" do
    #     xml = subject.build_available_actions_to_request
    #     expect(xml).to match /SalesOrderQueryRq/
    #   end
    # end
  end
end
