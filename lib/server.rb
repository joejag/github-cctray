# frozen_string_literal: true

require "sinatra"
require "json"
require_relative "./github/client"
require_relative "./cctray"

get "/" do
  # redirect to example project
  redirect "/build-canaries/nevergreen/nevergreen.yml"
end

get "/:group/:repo/:workflow" do |group, repo, workflow|
  content_type "application/xml"

  CCTray.new.status(group: group, repo: repo, workflow: workflow, xml: true)
end

