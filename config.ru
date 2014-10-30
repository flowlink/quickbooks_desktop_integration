require 'sinatra/base'

require './quickbooks_desktop_endpoint'
require './qbwc_endpoint'

run Rack::URLMap.new \
  '/' => QuickbooksDesktopEndpoint.new,
  '/qbwc' => QBWCEndpoint.new
