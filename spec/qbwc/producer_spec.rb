require 'spec_helper'

module QBWC
  describe Producer do
    before do
      allow(Persistence::Session).to receive(:save).and_return('1f8d3ff5-6f6c-43d6-a084-0ac95e2e29ad')
    end

    it 'build all request xml available per account' do
      skip('outdated vcr cassette')
      subject = described_class.new connection_id: '54591b3a5869632afc090000'

      VCR.use_cassette 'producer/454325352345' do
        xml = subject.build_available_actions_to_request
      end
    end

    it 'builds request xml for polling flows' do
      skip('outdated vcr cassette')
      subject = described_class.new connection_id: '54616145436f6e2fda030000'

      VCR.use_cassette 'producer/543453253245353' do
        xml = subject.build_polling_request
        expect(xml).to match /ItemInventoryQueryRq/
      end
    end

    it 'returns empty string if theres no polling config available' do
      skip('outdated vcr cassette')
      subject = described_class.new connection_id: 'nonoNONONONONONOOOOOOO'

      VCR.use_cassette 'producer/45435323452352352' do
        xml = subject.build_polling_request
        expect(xml).to eq ''
      end
    end

    # how about not support update orders instead?!!
    #
    # it "builds request xml for sales order query" do
    #   subject = described_class.new connection_id: '54591b3a5869632afc090000'

    #   VCR.use_cassette "producer/452435543524532" do
    #     xml = subject.build_available_actions_to_request
    #     expect(xml).to match /SalesOrderQueryRq/
    #   end
    # end

    context  '#build_polling_request' do
      describe '/get_customers' do
        it 'uses given since-date in query' do
          subject = described_class.new({connection_id: '54591b3a5869632afc090000'}, {})
          since_date = "2020-03-01T06:39:43-08:00"
          allow_any_instance_of(Persistence::Settings).to receive(:settings).and_return(
            [
              {
                customers: {
                  "connection_id" => "nurelmremote",
                  "flow" => "get_customers",
                  "origin" => "flowlink",
                  "quickbooks_since" => since_date,
                }
              }
            ]
          )

          request = subject.build_polling_request
          expect(request).to include('CustomerQueryRq')
          expect(request).to include(since_date)
        end
      end

      describe '/get_products' do
        it 'uses given since-date in query' do
          subject = described_class.new({connection_id: '54591b3a5869632afc090000'}, {})
          since_date = "2020-03-01T06:39:43-08:00"
          allow_any_instance_of(Persistence::Settings).to receive(:settings).and_return(
            [
              {
                products: {
                  "connection_id" => "nurelmremote",
                  "flow" => "get_products",
                  "origin" => "flowlink",
                  "quickbooks_since" => since_date,
                }
              }
            ]
          )

          request = subject.build_polling_request
          expect(request).to include('ItemInventoryQueryRq')
          expect(request).to include(since_date)
        end
      end

      describe '/get_vendors' do
        it 'uses given since-date in query' do
          subject = described_class.new({connection_id: '54591b3a5869632afc090000'}, {})
          since_date = "2020-03-01T06:39:43-08:00"
          allow_any_instance_of(Persistence::Settings).to receive(:settings).and_return(
            [
              {
                vendors: {
                  "connection_id" => "nurelmremote",
                  "flow" => "get_vendors",
                  "origin" => "flowlink",
                  "quickbooks_since" => since_date,
                }
              }
            ]
          )

          request = subject.build_polling_request
          expect(request).to include('VendorQueryRq')
          expect(request).to include(since_date)
        end
      end
    end

  end
end
