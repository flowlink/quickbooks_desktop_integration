require 'spec_helper'

module QBWC
  module Request
    describe Inventories do
      subject { described_class }

      before do
        allow_any_instance_of(Persistence::Object).to receive(:save_session).and_return("1f8d3ff5-6f6c-43d6-a084-0ac95e2e29ad")
      end

      it "parses timestamp and return request xml" do
        time = Time.now.utc.to_s
        xml = subject.polling_xml(time, {})
        expect(xml).to match time.split.first
      end
    end
  end
end
