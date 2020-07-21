require 'spec_helper'

describe QBWC::Response::All do
  before(:each) do
    Aws.config[:stub_responses] = true
  end

  subject { described_class.new Factory.item_query_rs_qbxml }

  describe '#process' do
    it 'process the response' do
      expect_any_instance_of(QBWC::Response::ItemInventoryQueryRs).to receive(:process)
      subject.process
    end
  end
end
