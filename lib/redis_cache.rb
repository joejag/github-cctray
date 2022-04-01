require "json"
require "redis"

class RedisCache
  def initialize(redis_pool: )
    @redis_pool = redis_pool
    # @redis = redis || Redis.new(url: ENV["REDIS_URL"])
  end

  def read(key)
    if (content = redis_pool.with { |redis| redis.get(key) })
      JSON.parse(content)
    end
  end

  def write(key, value)
    redis_pool.with { |redis| redis.set(key, value.to_json) }
  end

  private

  attr_reader :redis_pool
end
