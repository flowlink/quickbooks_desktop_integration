require 'spec_helper'

module QuickbooksDesktopIntegration
  describe Product do
    it "builds wombat products from xml response" do
      subject = Product.new Factory.item_inventory_add_rs_qbxml
      expect(subject.mapped_records.size).to eq(1)
      expect(subject.mapped_records[0][:id]).to eq('SPREE-T-SHIRT-1')
    end
  end
end
