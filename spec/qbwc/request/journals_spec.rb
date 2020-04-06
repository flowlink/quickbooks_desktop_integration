require 'rspec'
require 'json'
require 'qbwc/request/journals'
require 'qbwc/request/journal_fixtures/actions_xml_fixtures'

RSpec.describe QBWC::Request::Journals do
  let(:flowlink_journal) { JSON.parse(File.read('spec/qbwc/request/journal_fixtures/journal_from_flowlink.json')) }

  it 'calls add_xml_to_send and outputs the right data' do
    journal = QBWC::Request::Journals.add_xml_to_send(flowlink_journal, {}, 12345)
    expect(journal.gsub(/\s+/, '')).to eq(qbe_journal_add.gsub(/\s+/, ''))
  end

  it 'calls update_xml_to_send and outputs the right data' do
    journal = QBWC::Request::Journals.update_xml_to_send(flowlink_journal, {}, 12345)
    expect(journal.gsub(/\s+/, '')).to eq(qbe_journal_update.gsub(/\s+/, ''))
  end

  it 'calls search_xml_by_id and outputs the right data' do
    journal = QBWC::Request::Journals.search_xml(flowlink_journal["id"], 12345)
    expect(journal.gsub(/\s+/, '')).to eq(qbe_journal_search.gsub(/\s+/, ''))
  end
  
  it 'calls delete_xml_to_send and outputs the right data' do
    journal = QBWC::Request::Journals.delete_xml_to_send(flowlink_journal, 12345)
    expect(journal.gsub(/\s+/, '')).to eq(qbe_journal_delete.gsub(/\s+/, ''))
  end
end