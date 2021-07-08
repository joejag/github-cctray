# frozen_string_literal: true

ruby "3.0.2"

source "https://rubygems.org"

gem "activesupport"
gem "connection_pool"
gem "rack"
gem "redis"
gem "sinatra"
gem "srp-api", github: "srpatx/srp-api", require: false
gem "xml-simple"

group :development do
  gem "srp-style", require: false, github: "srpatx/srp-style"
end

group :test do
  gem "rake"
  gem "rspec"
  gem "rspec-its"
  gem "rspec-match_fuzzy"
  gem "webmock"
end

