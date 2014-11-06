require 'spec_helper'

describe QBWC::Response::ItemInventoryQueryRs do
  subject { described_class.new Factory.item_query_rs_hash }

  describe '#to_wombat' do
    it 'converts to wombat format' do
      expect(subject.send(:to_wombat).size).to eq 4
    end
  end
end
