require 'spec_helper'

describe QuickbooksDesktopIntegration::ProductQuery do
  subject { described_class.new Factory.item_query_rs_qbxml }

  it 'builds wombat products from XML response' do
    expect(subject.mapped_records.size).to eq 4
  end
end
