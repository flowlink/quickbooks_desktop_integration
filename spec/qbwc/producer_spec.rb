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

        it 'does not use given since-date in query' do
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
                  "return_all" => "1"
                }
              }
            ]
          )

          request = subject.build_polling_request
          expect(request).to include('CustomerQueryRq')
          expect(request).not_to include(since_date)
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

        it 'does not use given since-date in query' do
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
                  "return_all" => "1"
                }
              }
            ]
          )

          request = subject.build_polling_request
          expect(request).to include('ItemInventoryQueryRq')
          expect(request).not_to include(since_date)
        end
      end

      describe '/get_inventoryproducts' do
        it 'uses given since-date in query' do
          subject = described_class.new({connection_id: '54591b3a5869632afc090000'}, {})
          since_date = "2020-03-01T06:39:43-08:00"
          allow_any_instance_of(Persistence::Settings).to receive(:settings).and_return(
            [
              {
                inventoryproducts: {
                  "connection_id" => "nurelmremote",
                  "flow" => "get_inventoryproducts",
                  "origin" => "flowlink",
                  "quickbooks_since" => since_date,
                }
              }
            ]
          )

          request = subject.build_polling_request
          expect(request).to include('ItemInventoryQueryRq')
          expect(request).not_to include('ItemNonInventoryQueryRq')
          expect(request).to include(since_date)
        end
        
        it 'uses given since-date in query' do
          subject = described_class.new({connection_id: '54591b3a5869632afc090000'}, {})
          since_date = "2020-03-01T06:39:43-08:00"
          allow_any_instance_of(Persistence::Settings).to receive(:settings).and_return(
            [
              {
                inventoryproducts: {
                  "connection_id" => "nurelmremote",
                  "flow" => "get_inventoryproducts",
                  "origin" => "flowlink",
                  "quickbooks_since" => since_date,
                  "return_all" => "1"
                }
              }
            ]
          )

          request = subject.build_polling_request
          expect(request).to include('ItemInventoryQueryRq')
          expect(request).not_to include('ItemNonInventoryQueryRq')
          expect(request).not_to include(since_date)
        end
      end

      describe 'noninventory params products' do
        it 'only returns ItemNonInventoryQueryRq without since date' do
          subject = described_class.new({connection_id: '54591b3a5869632afc090000'}, {})
          since_date = "2020-03-01T06:39:43-08:00"
          allow_any_instance_of(Persistence::Settings).to receive(:settings).and_return(
            [
              {
                products: {
                  "connection_id" => "nurelmremote",
                  "quickbooks_since" => since_date,
                  "flow" => "get_products",
                  "origin" => "flowlink",
                  "return_all" => "1",
                  "quickbooks_force_config" => "1",
                  "quickbooks_specify_products" => "[\"noninventory\"]"
                }
              }
            ]
          )

          request = subject.build_polling_request
          expect(request).to include('ItemNonInventoryQueryRq')
          expect(request).not_to include('ItemInventoryQueryRq')
          expect(request).not_to include(since_date)
        end

        it 'only returns ItemNonInventoryQueryRq and since date' do
          subject = described_class.new({connection_id: '54591b3a5869632afc090000'}, {})
          since_date = "2020-03-01T06:39:43-08:00"
          allow_any_instance_of(Persistence::Settings).to receive(:settings).and_return(
            [
              {
                products: {
                  "connection_id" => "nurelmremote",
                  "quickbooks_since" => since_date,
                  "flow" => "get_products",
                  "origin" => "flowlink",
                  "quickbooks_force_config" => "1",
                  "quickbooks_specify_products" => "[\"noninventory\"]"
                }
              }
            ]
          )

          request = subject.build_polling_request
          expect(request).to include('ItemNonInventoryQueryRq')
          expect(request).not_to include('ItemInventoryQueryRq')
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

        it 'does not use given since-date in query' do
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
                  "return_all" => "1"
                }
              }
            ]
          )

          request = subject.build_polling_request
          expect(request).to include('VendorQueryRq')
          expect(request).not_to include(since_date)
        end
      end

      describe '/get_serviceproducts' do
        it 'uses given since-date in query' do
          subject = described_class.new({connection_id: '54591b3a5869632afc090000'}, {})
          since_date = "2020-03-01T06:39:43-08:00"
          allow_any_instance_of(Persistence::Settings).to receive(:settings).and_return(
            [
              {
                serviceproducts: {
                  "connection_id" => "nurelmremote",
                  "flow" => "get_serviceproducts",
                  "origin" => "flowlink",
                  "quickbooks_since" => since_date,
                }
              }
            ]
          )

          request = subject.build_polling_request
          expect(request).to include('ItemServiceQueryRq')
          expect(request).to include(since_date)
        end

        it 'does not use given since-date in query' do
          subject = described_class.new({connection_id: '54591b3a5869632afc090000'}, {})
          since_date = "2020-03-01T06:39:43-08:00"
          allow_any_instance_of(Persistence::Settings).to receive(:settings).and_return(
            [
              {
                serviceproducts: {
                  "connection_id" => "nurelmremote",
                  "flow" => "get_serviceproducts",
                  "origin" => "flowlink",
                  "quickbooks_since" => since_date,
                  "return_all" => "1"
                }
              }
            ]
          )

          request = subject.build_polling_request
          expect(request).to include('ItemServiceQueryRq')
          expect(request).not_to include(since_date)
        end
      end

      describe '/get_salestaxproducts' do
        it 'uses given since-date in query' do
          subject = described_class.new({connection_id: '54591b3a5869632afc090000'}, {})
          since_date = "2020-03-01T06:39:43-08:00"
          allow_any_instance_of(Persistence::Settings).to receive(:settings).and_return(
            [
              {
                salestaxproducts: {
                  "connection_id" => "nurelmremote",
                  "flow" => "get_salestaxproducts",
                  "origin" => "flowlink",
                  "quickbooks_since" => since_date,
                }
              }
            ]
          )

          request = subject.build_polling_request
          expect(request).to include('ItemSalesTaxQueryRq')
          expect(request).to include(since_date)
        end

        it 'does not use given since-date in query' do
          subject = described_class.new({connection_id: '54591b3a5869632afc090000'}, {})
          since_date = "2020-03-01T06:39:43-08:00"
          allow_any_instance_of(Persistence::Settings).to receive(:settings).and_return(
            [
              {
                salestaxproducts: {
                  "connection_id" => "nurelmremote",
                  "flow" => "get_salestaxproducts",
                  "origin" => "flowlink",
                  "quickbooks_since" => since_date,
                  "return_all" => "1"
                }
              }
            ]
          )

          request = subject.build_polling_request
          expect(request).to include('ItemSalesTaxQueryRq')
          expect(request).not_to include(since_date)
        end
      end

      describe '/get_discountproducts' do
        it 'uses given since-date in query' do
          subject = described_class.new({connection_id: '54591b3a5869632afc090000'}, {})
          since_date = "2020-03-01T06:39:43-08:00"
          allow_any_instance_of(Persistence::Settings).to receive(:settings).and_return(
            [
              {
                discountproducts: {
                  "connection_id" => "nurelmremote",
                  "flow" => "get_discountproducts",
                  "origin" => "flowlink",
                  "quickbooks_since" => since_date,
                }
              }
            ]
          )

          request = subject.build_polling_request
          expect(request).to include('ItemDiscountQueryRq')
          expect(request).to include(since_date)
        end

        it 'does not use given since-date in query' do
          subject = described_class.new({connection_id: '54591b3a5869632afc090000'}, {})
          since_date = "2020-03-01T06:39:43-08:00"
          allow_any_instance_of(Persistence::Settings).to receive(:settings).and_return(
            [
              {
                discountproducts: {
                  "connection_id" => "nurelmremote",
                  "flow" => "get_discountproducts",
                  "origin" => "flowlink",
                  "quickbooks_since" => since_date,
                  "return_all" => "1"
                }
              }
            ]
          )

          request = subject.build_polling_request
          expect(request).to include('ItemDiscountQueryRq')
          expect(request).not_to include(since_date)
        end
      end

      describe '/get_noninventoryproducts' do
        it 'uses given since-date in query' do
          subject = described_class.new({connection_id: '54591b3a5869632afc090000'}, {})
          since_date = "2020-03-01T06:39:43-08:00"
          allow_any_instance_of(Persistence::Settings).to receive(:settings).and_return(
            [
              {
                noninventoryproducts: {
                  "connection_id" => "nurelmremote",
                  "flow" => "get_noninventoryproducts",
                  "origin" => "flowlink",
                  "quickbooks_since" => since_date,
                }
              }
            ]
          )

          request = subject.build_polling_request
          expect(request).to include('ItemNonInventoryQueryRq')
          expect(request).to include(since_date)
        end

        it 'does not use given since-date in query' do
          subject = described_class.new({connection_id: '54591b3a5869632afc090000'}, {})
          since_date = "2020-03-01T06:39:43-08:00"
          allow_any_instance_of(Persistence::Settings).to receive(:settings).and_return(
            [
              {
                noninventoryproducts: {
                  "connection_id" => "nurelmremote",
                  "flow" => "get_noninventoryproducts",
                  "origin" => "flowlink",
                  "quickbooks_since" => since_date,
                  "return_all" => "1"
                }
              }
            ]
          )

          request = subject.build_polling_request
          expect(request).to include('ItemNonInventoryQueryRq')
          expect(request).not_to include(since_date)
        end
      end

      describe '/get_purchaseorders' do
        it 'uses given since-date in query' do
          subject = described_class.new({connection_id: '54591b3a5869632afc090000'}, {})
          since_date = "2020-03-01T06:39:43-08:00"
          allow_any_instance_of(Persistence::Settings).to receive(:settings).and_return(
            [
              {
                purchaseorders: {
                  "connection_id" => "nurelmremote",
                  "flow" => "get_purchaseorders",
                  "origin" => "flowlink",
                  "quickbooks_since" => since_date,
                }
              }
            ]
          )

          request = subject.build_polling_request
          expect(request).to include('PurchaseOrderQueryRq')
          expect(request).to include(since_date)
        end
      end

      describe '/get_salesreceipts' do
        it 'uses given since-date in query' do
          subject = described_class.new({connection_id: '54591b3a5869632afc090000'}, {})
          since_date = "2020-03-01T06:39:43-08:00"
          allow_any_instance_of(Persistence::Settings).to receive(:settings).and_return(
            [
              {
                salesreceipts: {
                  "connection_id" => "nurelmremote",
                  "flow" => "get_salesreceipts",
                  "origin" => "flowlink",
                  "quickbooks_since" => since_date,
                }
              }
            ]
          )

          request = subject.build_polling_request
          expect(request).to include('SalesReceiptQueryRq')
          expect(request).to include(since_date)
        end
      end

      describe '/get_orders' do
        it 'uses given since-date in query' do
          subject = described_class.new({connection_id: '54591b3a5869632afc090000'}, {})
          since_date = "2020-03-01T06:39:43-08:00"
          allow_any_instance_of(Persistence::Settings).to receive(:settings).and_return(
            [
              {
                orders: {
                  "connection_id" => "nurelmremote",
                  "flow" => "get_orders",
                  "origin" => "flowlink",
                  "quickbooks_since" => since_date,
                }
              }
            ]
          )

          request = subject.build_polling_request
          expect(request).to include('SalesOrderQueryRq')
          expect(request).to include(since_date)
        end
      end

      describe '/get_invoices' do
        it 'uses given since-date in query' do
          subject = described_class.new({connection_id: '54591b3a5869632afc090000'}, {})
          since_date = "2020-03-01T06:39:43-08:00"
          allow_any_instance_of(Persistence::Settings).to receive(:settings).and_return(
            [
              {
                invoices: {
                  "connection_id" => "nurelmremote",
                  "flow" => "get_invoices",
                  "origin" => "flowlink",
                  "quickbooks_since" => since_date,
                }
              }
            ]
          )

          request = subject.build_polling_request
          expect(request).to include('InvoiceQueryRq')
          expect(request).to include(since_date)
        end
      end
    end

    context  '#process_insert_update' do
      it 'adding a customer' do
        subject = described_class.new({connection_id: '54591b3a5869632afc090000'}, {})
        allow_any_instance_of(Persistence::Settings).to receive(:settings).and_return(
          [
            {
              customers: {
                "connection_id" => "nurelmremote",
                "flow" => "add_customers",
                "origin" => "flowlink",
              }
            }
          ]
        )

        objects =  [
          {
            "customers" => {
              "id"=>"-1475696078",
              "key"=>"systum_id",
              "name"=>"Test customer",
              "email"=>"test@flowlink.io",
              "phone"=>"000-111-2222",
              "since"=>"2019-05-21T14:36:41.094Z",
              "terms"=>"Net 30",
              "title"=>"Miss",
              "is_b2b"=>true,
              "mobile"=>"+1 ",
              "qbe_id"=>"800006PI-1455898078",
              "status"=>"ACTIVE",
              "balance"=>"0.00",
              "company"=>"Test Company",
              "list_id"=>nil, "site_id"=>nil,
              "tax_ref"=>"Out of State", "lastname"=>"", "firstname"=>"",
              "full_name"=>"Test customer", "is_active"=>true,
              "last_name"=>"customer",
              "systum_id"=>87279, "created_at"=>"2019-05-21T14:36:41.094Z",
              "first_name"=>"John", "hide_carts"=>false,
              "job_status"=>"None", "sub_status"=>"",
              "external_id"=>"800006EB-1475696078",
              "modified_at"=>"2019-08-06T15:49:23-05:00",
              "job_end_date"=>nil, "is_individual"=>false,
              "total_balance"=>"0.00", "account_number"=>"2267",
              "job_start_date"=>nil, "sales_tax_code"=>"Tax",
              "billing_address"=> {
                "city"=>"Pittsburgh",
                "name"=>"Test Customer",
                "phone"=>"000-111-2222",
                "state"=>"PA",
                "country"=>"United States",
                "zipcode"=>"94590",
                "address1"=>"1928 E Main AVE",
                "address2"=>"", "lastname"=>"", "firstname"=>""
              },
              "ship_to_address"=> {
                "city"=>"Pittsburgh",
                "name"=>"Test Customer",
                "phone"=>"000-111-2222",
                "state"=>"PA",
                "country"=>"United States",
                "zipcode"=>"94590",
                "address1"=>"1928 E Main AVE",
                "address2"=>"", "lastname"=>"", "firstname"=>""
              },
              "email_preference"=>"opt_in",
              "last_transaction"=>nil,
              "shipping_address"=>{
                "city"=>"Pittsburgh",
                "name"=>"Test Customer",
                "phone"=>"000-111-2222",
                "state"=>"PA",
                "country"=>"United States",
                "zipcode"=>"94590",
                "address1"=>"1928 E Main AVE",
                "address2"=>"", "lastname"=>"", "firstname"=>""
              },
              "preferred_payment_method_name"=>"Credit Card",
              "request_id"=>"3bce6ca2-e78b-4daa-b563-44a73a6f3e60",
              "edit_sequence"=>nil,
              "object_type"=>"customers"
            }
          }
        ]

        request = subject.send(:process_insert_update, objects)
        expect(request).to include('CustomerAddRq')
      end
    end

  end
end
