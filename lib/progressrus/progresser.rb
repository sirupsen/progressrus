module Progressrus
  class Progresser
    PERSISTANCE_INTERVAL = 2

    attr_reader :scope, :count, :total, :started_at, :id,
      :store, :job, :params, :completed_at
    attr_accessor :total

    def initialize(params, store = Progressrus.store)
      @scope        = params.delete(:scope).map(&:to_s)
      @total        = params.delete(:total)
      @id           = (params.delete(:id) || SecureRandom.uuid).to_s
      @interval     = (params.delete(:interval) || PERSISTANCE_INTERVAL).to_i
      @params       = params
      @count        = 0
      @started_at   = Time.now
      @persisted_at = Time.now - @interval - 1
      @store        = store
      @completed_at = nil
    end

    def tick(ticks = 1)
      @count += ticks
      persist if outdated?
    end

    def complete
      @completed_at = Time.now
      persist
    end

    def name
      @params[:name]
    end

    def to_serializeable
      raise ArgumentError, "Total must be set." unless total

      {
        count:        count,
        total:        total,
        started_at:   started_at,
        completed_at: completed_at,
        id:           id,
        scope:        scope,
        name:         name
      }.merge(params)
    end

    private
    def persist
      store.persist(self)
      @persisted_at = Time.now
    end

    def outdated?
      (Time.now - @interval) > @persisted_at
    end
  end
end
