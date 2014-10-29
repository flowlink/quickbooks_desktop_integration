module QuickbooksDesktopIntegration
  class Order < Base
    attr_reader :orders, :config

    def initialize(config, payload)
      @orders = payload[:orders]
      @config = config
    end

    # NOTE it doesn't check whether the order is already in s3
    def save_to_s3
      folder = "to_be_integrated"
      name = "#{config[:connection_id]}_orders_#{Time.now.to_i}"
      file = "#{folder}/#{name}.csv"

      amazon_s3.export file_name: file, objects: orders
    end
  end
end
