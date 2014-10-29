require 'spec_helper'

module QuickbooksDesktopIntegration
  describe Order do
    let(:orders) { Factory.orders }
    let(:config) { { connection_id: 'x123' } }

    subject { described_class.new config, orders }

    it "process orders" do
      VCR.use_cassette "order/1414612360" do
        subject.start_processing
      end
    end
  end
end
