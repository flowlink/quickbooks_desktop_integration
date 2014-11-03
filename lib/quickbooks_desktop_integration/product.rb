module QuickbooksDesktopIntegration
  class Product
    def convert_xml(xml)
      parser = Nori.new
      # im broken
      #
      #items = response['qbxml']['qbxml_msgs_rs']['item_query_rs'].except 'xml_attributes'

      #items.map do |item_type, item|
      #  {
      #    id: item['list_id'],
      #    name: item['name'],
      #    description: item['full_name'],
      #    item_type: item_type,
      #    active: item['is_active'],
      #    quickbooks: item
      #  }
      #end
    end
  end
end
