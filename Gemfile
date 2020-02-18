source 'https://rubygems.org'

gem 'rake'
gem 'sinatra'
gem 'sinatra-contrib' # For sinatra/reloader which autoreloads modules on change
gem 'tilt', '~> 1.4.1'
gem 'tilt-jbuilder', require: 'sinatra/jbuilder'
gem 'endpoint_base', github: 'flowlink/endpoint_base'
gem 'foreman'
gem 'unicorn'
gem 'nori'
gem 'aws-sdk'
gem 'fast_xs'
gem 'nokogiri'
gem 'i18n'

group :development do
  gem 'pry'
  gem 'shotgun'
end

group :development, :test do
  gem 'pry-byebug'
  gem 'dotenv'
end

group :test do
  gem 'vcr'
  gem 'webmock'
  gem 'simplecov'
  gem 'rspec'
  gem 'rack-test'
end
