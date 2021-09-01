require "sinatra"
require "json"
require "redis"
require "connection_pool"
require_relative "./github/client"
require_relative "./cctray"

redis_pool_size = ENV.fetch("REDIS_POOL_SIZE", 25)
redis_pool_timeout = ENV.fetch("REDIS_POOL_TIMEOUT", 5)
redis_url = ENV.fetch("REDIS_URL")
redis_pool = ConnectionPool.new(size: redis_pool_size, timeout: redis_pool_timeout) do
  Redis.new(url: redis_url)
end

get "/" do
  # redirect to example project
  redirect "/build-canaries/nevergreen/nevergreen.yml"
end

get "/:group/:repo/:workflow" do |group, repo, workflow|
  content_type "application/xml"

  CCTray.new(redis_pool: redis_pool).status(group: group, repo: repo, workflow: workflow, xml: true)
end

