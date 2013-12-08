require 'json'
require 'securerandom'
require 'redis'

class Progressrus
  def self.scope(scope, store = @@store)
    store.scope(scope)
  end

  def self.store=(store = Redis::Base.new)
    @@store = store
  end

  def self.store
    @@store
  end

  class Progresser
    attr_reader :total, :scope, :count, :total, :started_at, :id, :store

    def initialize(options, store = Progressrus.store)
      @scope        = options[:scope].map(&:to_s)
      @total        = options[:total].to_i
      @id           = options.fetch(:id, SecureRandom.uuid).to_s
      @interval     = options.fetch(:interval, 2).to_i
      @count        = 0
      @started_at   = Time.now
      @persisted_at = Time.now - @interval - 1
      @store        = store
    end

    def tick(ticks = 1)
      @count += ticks
      persist if outdated?
    end

    private
    def persist
      @store.persist(self)
      @persisted_at = Time.now
    end

    def outdated?
      (@started_at - @interval) > @persisted_at
    end
  end

  class Tick
    def initialize(options)
      @options = options
    end

    def count
      @options[:count]
    end

    def total
      @options[:total]
    end

    def started_at
      @options[:started_at]
    end

    def elapsed
      (Time.now - started_at).to_i
    end

    def percentage
      count.to_f / total
    end

    def eta
      processed_per_second = (count.to_f / elapsed)
      left = (total - count)
      seconds_to_finished = left * processed_per_second
      Time.now + seconds_to_finished
    end
  end

  module Store
    class NotImplementedError < StandardError; end

    class Base
      def persist(progressrus)
        raise NotImplementedError
      end
    end

    class Redis < Base
      KEY_PREFIX = "progressrus"

      def initialize(redis = ::Redis.new)
        @redis = redis
      end

      def persist(progress)
        @redis.hset(key(progress.scope), progress.id, {
          count:      progress.count,
          total:      progress.total,
          started_at: progress.started_at
        }.to_json)
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
