require 'simplecov'
require 'rubygems'
require 'bundler'
require 'dotenv'
require 'aws-sdk'

Dotenv.load

SimpleCov.start do
  add_filter 'spec'
end

Bundler.require(:default, :test)

require File.join(File.dirname(__FILE__), '..', 'quickbooks_desktop_endpoint')
require File.join(File.dirname(__FILE__), '..', 'qbwc_endpoint')

Dir['./spec/support/**/*.rb'].each { |f| require f }

require 'spree/testing_support/controllers'

Sinatra::Base.environment = 'test'

VCR.configure do |c|
  c.allow_http_connections_when_no_cassette = false
  c.cassette_library_dir = 'spec/cassettes'
  c.hook_into :webmock

  # c.force_utf8_encoding = true

  c.filter_sensitive_data('SECRET_SAUCE') { ENV['AWS_SECRET_ACCESS_KEY'] }
  c.filter_sensitive_data('SHHHHHHHHHHH') { ENV['AWS_ACCESS_KEY_ID'] }
  c.filter_sensitive_data('AUTHORIZATION') do |interaction|
    interaction.request.headers['Authorization'][0]
  end

end

Aws.config[:stub_responses] = true

RSpec.configure do |config|
  config.include Rack::Test::Methods
  config.include Spree::TestingSupport::Controllers
end
