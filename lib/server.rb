# frozen_string_literal: true

require "sinatra"
require "json"
require_relative "./github/client"
require_relative "./github_to_cctray"

get "/" do
  # redirect to example project
  redirect "/build-canaries/nevergreen/nevergreen.yml"
end

get "/:group/:repo/:workflow" do |group, repo, workflow|
  content_type "application/xml"

  client = GitHub::Client.new(username: ENV["GITHUB_USERNAME"], token: ENV["GITHUB_TOKEN"])
  github_status = client.status(group: group, repo: repo, workflow: workflow)
  GithubToCCTray.new.convert_to_xml(github_status)
end

