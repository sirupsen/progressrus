class Progressrus
  class Store
    class Redis < Base
      BACKEND_EXCEPTIONS = [ ::Redis::BaseError ]

      attr_reader :redis, :interval, :prefix, :name

      def initialize(instance, prefix: "progressrus", interval: 1, now: Time.now)
        @name          = :redis
        @redis         = instance
        @persisted_ats = Hash.new({})
        @interval      = interval
        @prefix        = prefix
      end

      def persist(progress, now: Time.now, force: false, expires_at: nil)
        if outdated?(progress) || force
          key_for_scope = key(progress.scope)

          redis.with do |client|
            client.pipelined do |pipeline|
              pipeline.hset(key_for_scope, progress.id, progress.to_serializeable.to_json)
              pipeline.expireat(key_for_scope, expires_at.to_i) if expires_at
            end
          end

          @persisted_ats[progress.scope][progress.id] = now
        end
      rescue *BACKEND_EXCEPTIONS => e
        raise Progressrus::Store::BackendError.new(e)
      end

      def scope(scope)
        scope = redis.with do |client|
          client.hgetall(key(scope))
        end
        scope.each_pair { |id, value|
          scope[id] = Progressrus.new(**deserialize(value))
        }
      rescue *BACKEND_EXCEPTIONS => e
        raise Progressrus::Store::BackendError.new(e)
      end

      def find(scope, id)
        value = redis.with { |client| client.hget(key(scope), id) }
        return unless value

        Progressrus.new(**deserialize(value))
      rescue *BACKEND_EXCEPTIONS => e
        raise Progressrus::Store::BackendError.new(e)
      end

      def flush(scope, id = nil)
        redis.with do |client|
          if id
            client.hdel(key(scope), id)
          else
            client.del(key(scope))
          end
        end
      rescue *BACKEND_EXCEPTIONS => e
        raise Progressrus::Store::BackendError.new(e)
      end

      private

      def key(scope)
        if prefix.respond_to?(:call)
          prefix.call(scope)
        else
          "#{prefix}:#{scope.join(":")}"
        end
      end

      def deserialize(value)
        JSON.parse(value, symbolize_names: true).merge(persisted: true)
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
