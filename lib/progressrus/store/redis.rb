module Progressrus
  module Store
    class Redis < Base
      attr_accessor :expire
      attr_reader :redis, :prefix

      def initialize(redis = ::Redis.new, expire = 60 * 30, prefix = "progressrus")
        @redis = redis
        @expire = expire
        @prefix = prefix
      end

      def persist(scope, id, serializeable_hash)
        redis.hset(key(scope), id, serializeable_hash.to_json)
        redis.expire(key(scope), expire)
      end

      alias_method :complete, :persist

      def scope(scope)
        scope = redis.hgetall(key(scope))
        scope.each_pair { |id, value|
          scope[id] = Tick.new(JSON.parse(value, symbolize_names: true))
        }
      end

      def flush(s)
        key = key(s)
        scope(s).each_pair { |id, value| redis.hdel(key, id) }
      end

      private
      def key(scope)
        "#{prefix}:#{scope.join(":")}"
      end
    end
  end
end
