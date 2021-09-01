require_relative "../lib/redis_cache"

class FakeRedis
  def set(key, value)
    data[key] = value
  end

  def get(key)
    data[key]
  end

  private

  def data
    @data ||= {}
  end
end

class FakeRedisPool
  def initialize(redis)
    @redis = redis
  end

  attr_reader :redis

  def with
    yield(redis)
  end
end

describe RedisCache do
  let(:cache) { described_class.new(redis_pool: redis_pool) }
  let(:redis_pool) { FakeRedisPool.new(redis) }
  let(:redis) { FakeRedis.new }
  let(:key) { "wibble" }

  describe "#read" do
    subject { cache.read(key) }

    context "with a key that refers to a simple value" do
      let(:value) { 1 }
      before { redis.set(key, value.to_json) }
      it { should == value }
    end

    context "with a key that refers to a hash value" do
      let(:value) { { "a" => 1, "b" => 2 } }
      before { redis.set(key, value.to_json) }
      it { should == value }
    end

    context "with a key that does not refer to anything" do
      it { should be_nil }
    end
  end

  describe "#write" do
    subject { -> { cache.write(key, value) } }

    context "with a simple ruby object" do
      let(:value) { 666 }
      it { should change { cache.read(key) }.to(value) }
    end

    context "with a hash" do
      let(:value) { { "a" => 1, "b" => 2 } }
      it { should change { cache.read(key) }.to(value) }
    end

    context "with nil" do
      let(:value) { nil }
      before { redis.set(key, "anything".to_json) }
      it { should change { cache.read(key) }.to be_nil }
    end
  end
end

