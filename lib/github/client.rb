# frozen_string_literal: true

require "srp/api"
require_relative "../redis_cache"

module GitHub
  class Client
    include Srp::Api::Client

    def initialize(username: nil, token: nil, cache: nil)
      @username = username || ENV["GITHUB_USERNAME"]
      @token = token || ENV["GITHUB_TOKEN"]
      @cache = cache || RedisCache.new
      raise ArgumentError unless username && token
    end

    def runs(group: , repo: , workflow: )
      uri = URI("https://api.github.com/repos/#{group}/#{repo}/actions/workflows/#{workflow}/runs")

      cached_data = cache.read(uri.to_s)
      response = request(:get, uri, headers: { "If-None-Match": cached_data&.fetch("etag", nil) })

      if status_changed?(response)
        JSON.parse(response).tap do |runs|
          cache.write(uri.to_s, { etag: response.headers["ETag"], runs: runs })
        end
      else
        cached_data["runs"]
      end
    end

    private

    attr_reader :username, :token, :cache

    def request(method, uri, headers: {})
      response = HTTP
        .headers({ accept: "application/json" }.merge(headers))
        .basic_auth(user: username, pass: token)
        .request(method, uri)

      check_for_errors!(response, method, uri)
      response
    end

    def status_changed?(response)
      response.code != 304
    end
  end
end

