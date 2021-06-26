# frozen_string_literal: true

require 'sinatra'
require 'net/http'
require 'json'
require_relative './github_to_cctray.rb'

get '/' do
  # redirect to example project
  redirect '/build-canaries/nevergreen/nevergreen.yml'
end

get '/:group/:repo/:workflow' do |group, repo, workflow|
  content_type 'application/xml'

  response = Net::HTTP.get(URI("https://api.github.com/repos/#{group}/#{repo}/actions/workflows/#{workflow}/runs"))
  payload = JSON.parse(response)

  GithubToCCTray.new.convert_to_xml(payload, params[:branch])
end
