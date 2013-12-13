require 'json'
require 'securerandom'
require 'redis'
require_relative "progressrus/store"
require_relative "progressrus/store/base"
require_relative "progressrus/store/redis"

class Progressrus
  class << self
    def stores
      @@stores ||= Store.new(Store::Redis.new(::Redis.new(host: "10.0.0.10")))
    end

    def scope(scope, store: :first)
      stores.find_by_name(store).scope(scope)
    end
    alias_method :all, :scope

    def find(scope, id, store: :first)
      stores.find_by_name(store).scope(scope, id)
    end
  end

  attr_reader :name, :scope, :total, :id, :params, :store, :count, 
    :started_at, :completed_at, :stores

  alias_method :completed?, :completed_at
  alias_method :started?,   :started_at

  attr_writer :params

  def initialize(scope: "progressrus", total: nil, name: nil, 
    id: SecureRandom.uuid, params: {}, stores: Progressrus.stores,
    completed_at: nil, started_at: nil, count: 0)

    raise ArgumentError, "Total cannot be zero or negative." if total && total <= 0

    @name         = name || id
    @scope        = Array(scope).map(&:to_s)
    @total        = total
    @id           = id
    @params       = params
    @stores       = stores
    @count        = count
    @started_at   = started_at
    @completed_at = completed_at
  end

  def tick(ticks = 1, now: Time.now)
    @started_at ||= now if ticks >= 1
    @count += ticks
    persist
  end

  def complete(now: Time.now)
    @completed_at = now
    persist
  end

  def to_serializeable
    raise ArgumentError, "Total must be set before first tick." unless total

    {
      name:         name,
      id:           id,
      scope:        scope,
      started_at:   started_at,
      completed_at: completed_at,
      count:        count,
      total:        total,
      params:       params
    }
  end

  def total=(new_total)
    raise ArgumentError, "Total cannot be zero or negative." if new_total <= 0
    @total = new_total
  end

  def elapsed(now: Time.now)
    now - started_at
  end

  def percentage
    count.to_f / total
  end

  def eta(now: Time.now)
    return nil if count.to_i == 0

    processed_per_second = (count.to_f / elapsed(now: now))
    left = (total - count)
    seconds_to_finished = left / processed_per_second
    now + seconds_to_finished
  end

  private
  def persist
    stores.each { |store| store.persist(self) }
  end
end

require 'progressrus/railtie' if defined?(Rails)
