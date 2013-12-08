module Progressrus
  module Store
    class Redis < Base
      attr_accessor :expire
      attr_reader :redis

      KEY_PREFIX = "progressrus"

      def initialize(redis = ::Redis.new, expire = 60 * 30)
        @redis = redis
        @expire = expire
      end

      def persist(progress)
        @redis.hset(key(progress.scope), progress.id, {
          count:      progress.count,
          total:      progress.total,
          started_at: progress.started_at
        }.to_json)
        @redis.expire(key(progress.scope), @expire)
      end

      def scope(scope)
        scope = @redis.hgetall(key(scope))
        scope.each_pair { |id, value| 
          scope[id] = Tick.new(JSON.parse(value, symbolize_names: true))
        }
      end

      def flush
        @redis.flushall
      end

      private
      def key(scope)
        "#{KEY_PREFIX}:#{scope.join(":")}"
      end
    end
  end
end
