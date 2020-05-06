require 'spec_helper'

Aws.config[:stub_responses] = false

module Persistence
  describe Polling do
    it '#save_for_polling' do
      payload = { products: [] }
      config = { origin: 'quickbooks', connection_id: 'nurelmremote' }
      skip('Tests fail when the cassette is replayed because the timestamp keeps changing')
      VCR.use_cassette 'persistence/save_for_polling' do
        subject = described_class.new(config, payload)
        s3 = subject.save_for_polling
        expect(s3.key).to match "#{config[:connection_id]}/quickbooks_pending/#{payload.keys.first}_"
        expect(s3.key).to match /\d{10}/ # Timestamp is 10 digits long
      end
    end

    it '#save_for_polling_without_timestamp' do
      payload = { products: [] }
      config = { origin: 'quickbooks', connection_id: 'nurelmremote' }
      VCR.use_cassette 'persistence/save_for_polling_without_timestamp' do
        subject = described_class.new(config, payload)
        s3 = subject.save_for_polling_without_timestamp
        expect(s3.key).to match "#{config[:connection_id]}/quickbooks_pending/#{payload.keys.first}_"
      end
    end

  end

end
