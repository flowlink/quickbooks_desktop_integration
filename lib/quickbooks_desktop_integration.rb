$:.unshift File.dirname(__FILE__)

require 'amazon_s3'

module QuickbooksDesktopIntegration
  class Base
    def amazon_s3
      @amazon_s3 ||= AmazonS3.new
    end
  end
end

require 'quickbooks_desktop_integration/order'
