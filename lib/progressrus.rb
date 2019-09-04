require 'json'
require 'securerandom'
require 'redis'
require 'time'
require_relative "progressrus/store/base"
require_relative "progressrus/store/redis"
require_relative "progressrus/store/progressbar"
require_relative "progressrus/core_ext/enumerable"

class Progressrus
  @mutex = Mutex.new

  class InvalidStoreError < StandardError
    def initialize
      message = <<~MSG
        The store needs to implement `persist`, `scope`, `find` and `flush`
        We have a base class that your store can inherit from:
          Progressrus::Store::Base
      MSG
      super(message)
    end
  end

  class StoreNotFoundError < StandardError
    def initialize(store)
      message = <<~MSG
        The store `#{store}` does not exists.
        Available stores: #{Progressrus.stores.keys.join(', ')}
      MSG
      super(message)
    end
  end

  class << self
    attr_reader :mutex

    def clear_stores
      @stores = {}
    end

    def stores
      mutex.synchronize do
        @stores ||= {
          redis: Store::Redis.new(::Redis.new(host: ENV["PROGRESSRUS_REDIS_HOST"] || "localhost"))
        }
      end
    end

    def add_store(name, store)
      validate_store!(store)
      stores[name] = store
    end

    def scope(scope, store: :redis)
      stores[store].scope(scope)
    end
    alias_method :all, :scope

    def find(scope, id, store: :redis)
      stores[store].find(scope, id)
    end

    def flush(scope, id = nil, store: :redis)
      stores[store].flush(scope, id)
    end

    private

    def validate_store!(store)
      valid = Store::Base.new.public_methods(false).all? do |method|
        store.respond_to?(method)
      end
      raise InvalidStoreError unless valid
    end
  end

  attr_reader :name, :scope, :total, :id, :params, :store, :count,
    :started_at, :completed_at, :failed_at, :expires_at, :stores, :error_count

  alias_method :completed?, :completed_at
  alias_method :started?,   :started_at
  alias_method :failed?,    :failed_at

  attr_writer :params

  def initialize(scope: "progressrus", total: nil, name: nil,
    id: SecureRandom.uuid, params: {}, stores: nil,
    completed_at: nil, started_at: nil, count: 0, failed_at: nil,
    error_count: 0, persist: false, expires_at: nil, persisted: false)

    raise ArgumentError, "Total cannot be negative." if total && total < 0

    @name         = name || id
    @scope        = Array(scope).map(&:to_s)
    @total        = total
    @id           = id
    @params       = params
    @stores       = extract_stores(stores)
    @count        = count
    @error_count  = error_count

    @started_at   = parse_time(started_at)
    @completed_at = parse_time(completed_at)
    @failed_at    = parse_time(failed_at)
    @expires_at   = parse_time(expires_at)
    @persisted    = persisted

    persist(force: true) if persist
  end

  def tick(ticks = 1, now: Time.now)
    @started_at ||= now if ticks >= 1
    @count += ticks
    persist
  end

  def error(ticks = 1, now: Time.now)
    @error_count ||= 0
    @error_count += ticks
  end

  def count=(new_count, **args)
    tick(new_count - @count, *args)
  end

  def complete(now: Time.now)
    @started_at ||= now
    @completed_at = now
    persist(force: true)
  end

  def flush
    stores.each_value { |store| store.flush(scope, id) }
  end

  def status
    return :completed if completed?
    return :failed if failed?
    return :running if running?
    :started
  end

  def running?
    count > 0
  end

  def fail(now: Time.now)
    @started_at ||= now
    @failed_at = now
    persist(force: true)
  end

  def to_serializeable
    {
      name:         name,
      id:           id,
      scope:        scope,
      started_at:   started_at,
      completed_at: completed_at,
      failed_at:    failed_at,
      expires_at:   expires_at,
      count:        count,
      total:        total,
      params:       params,
      error_count:  error_count
    }
  end

  def total=(new_total)
    raise ArgumentError, "Total cannot be negative." if new_total < 0
    @total = new_total
    persist(force: true) if persisted?
    @total
  end

  def elapsed(now: Time.now)
    now - started_at
  end

  def percentage
    return unless total

    if total > 0
      count.to_f / total
    else
      1.0
    end
  end

  def eta(now: Time.now)
    return if count.to_i == 0 || total.to_i == 0

    processed_per_second = (count.to_f / elapsed(now: now))
    left = (total - count)
    seconds_to_finished = left / processed_per_second
    now + seconds_to_finished
  end

  def expired?(now: Time.now)
    expires_at && expires_at < now
  end

  def persisted?
    @persisted
  end

  private

  def extract_stores(stores)
    return Progressrus.stores unless stores

    Array(stores).each_with_object({}) do |store, hash|
      stored_found = Progressrus.stores[store]
      raise StoreNotFoundError, store unless stored_found

      hash[store] = stored_found
    end
  end

  def persist(force: false)
    stores.each_value do |store|
      begin
        store.persist(self, force: force, expires_at: expires_at)
      rescue Progressrus::Store::BackendError
        # noop
      end
    end
    @persisted = true
  end

  def parse_time(time)
    return Time.parse(time) if time.is_a?(String)
    time
  end
end

require 'progressrus/railtie' if defined?(Rails)
