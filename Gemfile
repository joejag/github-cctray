# frozen_string_literal: true

ruby "2.7.2"

source "https://rubygems.org" do
  gem "http"
  gem "sinatra"
  gem "srp-api", github: "StrongholdResourcePartners/srp-api", require: false
  gem "xml-simple"

  group :development do
    gem "groundwork-style", require: false, github: "buildgroundwork/groundwork-style"
  end

  group :test do
    gem "activesupport"
    gem "rake"
    gem "rspec"
    gem "rspec-match_fuzzy"
    gem "webmock"
  end
end

