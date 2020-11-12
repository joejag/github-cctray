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

  username = ENV['GITHUB_USERNAME']
  token = ENV['GITHUB_TOKEN']
  raise 'Missing auth' unless username && token

  uri = URI("https://api.github.com/repos/#{group}/#{repo}/actions/workflows/#{workflow}/runs")

  response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
    request = Net::HTTP::Get.new(uri)
    request.basic_auth(username, token)
    http.request(request)
  end
  payload = JSON.parse(response.body)

  GithubToCCTray.new.convert_to_xml(payload)
end

