# frozen_string_literal: true

require "srp/api"

module GitHub
  class Client
    include Srp::Api::Client

    def initialize(username: nil, token: nil)
      @username = username || ENV["GITHUB_USERNAME"]
      @token = token || ENV["GITHUB_TOKEN"]
      raise ArgumentError unless username && token
    end

    def status(group: , repo: , workflow: )
      uri = URI("https://api.github.com/repos/#{group}/#{repo}/actions/workflows/#{workflow}/runs")
      request(:get, uri)
    end

    private

    attr_reader :username, :token

    def request(method, uri, **kwargs)
      response = HTTP
        .headers(accept: "application/json")
        .basic_auth(user: username, pass: token)
        .request(method, uri, **kwargs)

      check_for_errors!(response, method, uri)
      JSON.parse(response)
    end
  end
end

