# frozen_string_literal: true

require "json"
require "redis"

class RedisCache
  def initialize(redis: nil)
    @redis = redis || Redis.new(url: ENV["REDIS_URL"])
  end

  def read(key)
    if (content = redis.get(key))
      JSON.parse(content)
    end
  end

  def write(key, value)
    redis.set(key, value.to_json)
  end

  private

  attr_reader :redis
end

