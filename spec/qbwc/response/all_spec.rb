require 'spec_helper'

describe QBWC::Response::All do
  subject { described_class.new Factory.item_query_rs_qbxml }

  describe '#process' do
    it 'process the response' do
      expect_any_instance_of(QBWC::Response::ItemInventoryQueryRs).to receive(:process)
      subject.process
    end

    it "process sales order add rq fine" do
      subject = described_class.new Factory.sales_order_add_rs_raw_qbxml_raw
      subject.process
    end
  end
end
