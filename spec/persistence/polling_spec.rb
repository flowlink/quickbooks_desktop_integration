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

    context '#save_for_polling_without_timestamp' do
      it 'saves a file in s3 bucket' do
        payload = { products: [] }
        config = { origin: 'quickbooks', connection_id: 'nurelmremote' }
        VCR.use_cassette 'persistence/save_for_polling_without_timestamp' do
          subject = described_class.new(config, payload)
          s3 = subject.save_for_polling_without_timestamp
          expect(s3.key).to match "#{config[:connection_id]}/quickbooks_pending/#{payload.keys.first}_"
        end
      end

      it 'adds products together in one array' do
        # Already in the s3 bucket
        products = Factory.products

        product = Factory.product_single
        payload = { products: [product] }
        config = { origin: 'quickbooks', connection_id: 'nurelmremote' }
        VCR.use_cassette 'persistence/save_for_polling_without_timestamp_merging' do
          subject = described_class.new(config, payload)
          s3 = subject.save_for_polling_without_timestamp
          result = JSON.parse(s3.get.body.read)
          expect(s3.key).to match "#{config[:connection_id]}/quickbooks_pending/#{payload.keys.first}_"
          expect(result.size).to eq 2
        end
      end

      it 'merges products with the same id' do
        # Already in the s3 bucket
        products = Factory.products[:products] + [Factory.product_single]


        product = Factory.product_single.merge({ new_field: 'Giving a new field' })
        payload = { products: [product] }
        config = { origin: 'quickbooks', connection_id: 'nurelmremote' }
        VCR.use_cassette 'persistence/save_for_polling_without_timestamp_merging_products' do
          subject = described_class.new(config, payload)
          s3 = subject.save_for_polling_without_timestamp
          result = JSON.parse(s3.get.body.read)
          expect(s3.key).to match "#{config[:connection_id]}/quickbooks_pending/#{payload.keys.first}_"
          expect(result.size).to eq 2
          expect(result.first['new_field']).to eq product[:new_field]
        end
      end

      it 'merges changes the field with the same id' do
        # Already in the s3 bucket
        products = Factory.products[:products] + [Factory.product_single]


        product = Factory.product_single.merge({ description: 'new description' })
        payload = { products: [product] }
        config = { origin: 'quickbooks', connection_id: 'nurelmremote' }
        VCR.use_cassette 'persistence/save_for_polling_without_timestamp_merging_desc' do
          subject = described_class.new(config, payload)
          s3 = subject.save_for_polling_without_timestamp
          result = JSON.parse(s3.get.body.read)
          expect(s3.key).to match "#{config[:connection_id]}/quickbooks_pending/#{payload.keys.first}_"
          expect(result.size).to eq 2
          expect(result.first['description']).to eq product[:description]
        end
      end
    end

  end

end
