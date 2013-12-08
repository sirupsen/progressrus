module Progressrus
  class Progresser
    attr_reader :total, :scope, :count, :total, :started_at, :id, :store, :job, :params

    def initialize(options, params = {}, store = Progressrus.store)
      @scope        = options[:scope].map(&:to_s)
      @total        = options[:total].to_i
      @id           = options.fetch(:id, SecureRandom.uuid).to_s
      @interval     = options.fetch(:interval, 2).to_i
      @params       = params
      @count        = 0
      @started_at   = Time.now
      @persisted_at = Time.now - @interval - 1
      @store        = store
    end

    def tick(ticks = 1)
      @count += ticks
      persist if outdated?
    end

    def persist
      @store.persist(scope, id, to_serializeable)
      @persisted_at = Time.now
    end

    private
    def to_serializeable
      {
        count:      count,
        total:      total,
        started_at: started_at,
      }.merge(params)
    end

    def outdated?
      (@started_at - @interval) > @persisted_at
    end
  end
end
