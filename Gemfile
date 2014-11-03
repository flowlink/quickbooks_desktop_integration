source 'https://rubygems.org'

gem 'sinatra'
gem 'tilt', '~> 1.4.1'
gem 'tilt-jbuilder', require: 'sinatra/jbuilder'
gem 'endpoint_base', github: 'spree/endpoint_base'
gem 'foreman'
gem 'unicorn'
gem 'nori'
gem 'aws-sdk'
gem 'rake'
gem 'fast_xs'

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
