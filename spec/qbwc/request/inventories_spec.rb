require 'spec_helper'

module QBWC
  module Request
    describe Inventories do
      subject { described_class }

      it "parses timestamp and return request xml" do
        time = Time.now.utc.to_s
        xml = subject.polling_xml(time)
        expect(xml).to match time.split.first
      end
    end
  end
end
