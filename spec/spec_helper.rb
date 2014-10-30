require 'rubygems'
require 'bundler'
require 'dotenv'
Dotenv.load

Bundler.require(:default, :test)

require File.join(File.dirname(__FILE__), '..', 'lib/quickbooks_desktop_integration')
require File.join(File.dirname(__FILE__), '..', 'quickbooks_desktop_endpoint')

Dir["./spec/support/**/*.rb"].each { |f| require f }

require 'spree/testing_support/controllers'

Sinatra::Base.environment = 'test'

ENV['S3_ACCESS_KEY_ID'] ||= '123'
ENV['S3_SECRET_ACCESS_KEY'] ||= 'key'
ENV['S3_REGION'] ||= 'region'

VCR.configure do |c|
  c.allow_http_connections_when_no_cassette = false
  c.cassette_library_dir = 'spec/cassettes'
  c.hook_into :webmock

  #c.force_utf8_encoding = true

  c.filter_sensitive_data("S3_ACCESS_KEY_ID") { ENV["S3_ACCESS_KEY_ID"] }
  c.filter_sensitive_data("S3_SECRET_ACCESS_KEY") { ENV["S3_SECRET_ACCESS_KEY"] }
  c.filter_sensitive_data("S3_REGION") { ENV["S3_REGION"] }
end

RSpec.configure do |config|
  config.include Rack::Test::Methods
  config.include Spree::TestingSupport::Controllers
end
