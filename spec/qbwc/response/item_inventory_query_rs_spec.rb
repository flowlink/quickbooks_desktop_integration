require 'spec_helper'

describe QBWC::Response::ItemInventoryQueryRs do
  before(:each) do
    Aws.config[:stub_responses] = true
  end
  subject { described_class.new Factory.item_inventory_query_rs_hash }
  let(:config) { {connection_id: 123} }

  describe '#products_to_flowlink' do
    it 'converts to flowlink format' do
      expect(subject.send(:products_to_flowlink, config).size).to eq 1
    end
  end

  it 'sets records as an array' do
    records = Factory.item_inventory_query_rs_hash
    subject = described_class.new records
    expect(subject.send(:products_to_flowlink, config)).to be_a Array

    records = Factory.item_inventory_query_rs_multiple_hash
    subject = described_class.new records
    expect(subject.send(:products_to_flowlink, config)).to be_a Array
  end

  it 'parse empty response' do
    records = Factory.item_inventory_query_rs_empty_hash
    subject = described_class.new records
    expect(subject.send(:products_to_flowlink, config)).to be_empty
  end

  it 'persists inventories objects in s3' do
    config = {
      connection_id: '54591b3a5869632afc090000',
      receive: [{
        'inventories' => {
          connection_id: '54591b3a5869632afc090000',
          quickbooks_since: '2014-11-10T09:10:55Z'
        }
      }]
    }

    allow_any_instance_of(Persistence::Polling).to receive(:current_time).and_return('1415815242')

    VCR.use_cassette 'response/543543254325342' do
      subject.process config
    end
  end

  it 'persists products objects in s3' do
    config = {
      connection_id: '54591b3a5869632afc090000',
      receive: [{
        'products' => {
          connection_id: '54591b3a5869632afc090000',
          quickbooks_since: '2014-11-10T09:10:55Z'
        }
      }]
    }

    allow_any_instance_of(Persistence::Polling).to receive(:current_time).and_return('1415815266')

    VCR.use_cassette 'response/45423525325443253' do
      subject.process config
    end
  end

  describe "calls objects_to_update" do
    let(:qbe_product) { JSON.parse(File.read('spec/qbwc/response/generic_product_fixtures/product_from_qbe.json')) }
    let(:expected_object) {
      {
        object_type: 'product',
        object_ref: "test-product",
        product_id: "test-product",
        list_id: "80001019-2039019",
        edit_sequence: "190aMNia90jmdk"
      }
    }
    
    describe "calls objects_to_update with one product returned" do
      it "has no parent product names and outputs just the product name" do
        inventory_rs = QBWC::Response::ItemInventoryQueryRs.new([qbe_product])
        output = inventory_rs.send(:objects_to_update).first.with_indifferent_access

        expect(output).to eq(expected_object.with_indifferent_access)
      end

      it "has one parent product name as an object and outputs the parent name + : + product name" do
        expected_object[:object_ref] = "Parent Inventory:test-product"
        qbe_product["ParentRef"] = {
          "FullName" => "Parent Inventory"
        }
        
        inventory_rs = QBWC::Response::ItemInventoryQueryRs.new([qbe_product])
        output = inventory_rs.send(:objects_to_update).first.with_indifferent_access

        expect(output).to eq(expected_object.with_indifferent_access)
      end

      it "has one parent product name as an array and outputs the parent name + : + product name" do
        expected_object[:object_ref] = "Parent Inventory:test-product"
        qbe_product["ParentRef"] = [{
          "FullName" => "Parent Inventory"
        }]
        
        inventory_rs = QBWC::Response::ItemInventoryQueryRs.new([qbe_product])
        output = inventory_rs.send(:objects_to_update).first.with_indifferent_access

        expect(output).to eq(expected_object.with_indifferent_access)
      end

      it "has two parent product names as an object and outputs the parent names and product name correctly" do
        expected_object[:object_ref] = "Super Parent Inventory:Parent Inventory:test-product"
        qbe_product["ParentRef"] = {
          "FullName" => "Super Parent Inventory:Parent Inventory"
        }
        
        inventory_rs = QBWC::Response::ItemInventoryQueryRs.new([qbe_product])
        output = inventory_rs.send(:objects_to_update).first.with_indifferent_access

        expect(output).to eq(expected_object.with_indifferent_access)
      end

      it "has two parent product names as an array and outputs the parent names and product name correctly" do
        expected_object[:object_ref] = "Super Parent Inventory:Parent Inventory:test-product"
        qbe_product["ParentRef"] = [
          {"FullName" => "Super Parent Inventory"},
          {"FullName" => "Parent Inventory"}
        ]
        
        inventory_rs = QBWC::Response::ItemInventoryQueryRs.new([qbe_product])
        output = inventory_rs.send(:objects_to_update).first.with_indifferent_access

        expect(output).to eq(expected_object.with_indifferent_access)
      end
    end
  end
end
