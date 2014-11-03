require 'spec_helper'

module QuickbooksDesktopIntegration
  describe Product do
    it "builds wombat products from xml response" do
      subject.convert_xml Factory.item_query_rs_qbxml
    end
  end
end
