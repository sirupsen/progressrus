class Progressrus
  class Store
    class Redis < Base
      attr_reader :redis, :interval, :persisted_at, :prefix, :name

      def initialize(instance, prefix: "progressrus", interval: 1, now: Time.now)
        @name          = :redis
        @redis         = instance
        @persisted_ats = Hash.new({})
        @interval      = interval
        @prefix        = prefix
      end

      def persist(progress, now: Time.now)
        if outdated?(progress)
          redis.hset(key(progress.scope), progress.id, progress.to_serializeable.to_json)
          @persisted_ats[progress.scope][progress.id] = now
        end
      end

      def scope(scope)
        scope = redis.hgetall(key(scope))
        scope.each_pair { |id, value|
          scope[id] = Progressrus.new(deserialize(value))
        }
      end

      def find(scope, id)
        value = redis.hget(key(scope), id)
        return unless value

        Progressrus.new(deserialize(value))
      end

      def flush(scope, id = nil)
        if id
          redis.hdel(key(scope), id)
        else
          redis.del(key(scope))
        end
      end

      private
      def key(scope)
        "#{prefix}:#{scope.join(":")}"
      end

      def deserialize(value)
        JSON.parse(value, symbolize_names: true)
      end

      def outdated?(progress, now: Time.now)
        (now - interval).to_i >= persisted_at(progress).to_i
      end

      def persisted_at(progress)
        @persisted_ats[progress.scope][progress.id]
      end
    end
  end
end
