module Progressrus
  class Progresser
    attr_reader :scope, :count, :total, :started_at, :id, :store, :job, :params
    attr_accessor :total

    def initialize(params, store = Progressrus.store)
      @scope        = params.delete(:scope).map(&:to_s)
      @total        = params.delete(:total).to_i
      @id           = (params.delete(:id) || SecureRandom.uuid).to_s
      @interval     = (params.delete(:interval) || 2).to_i
      @params       = params
      @count        = 0
      @started_at   = Time.now
      @persisted_at = Time.now - @interval - 1
      @store        = store

      @params[:completed_at] = nil
    end

    def tick(ticks = 1)
      @count += ticks
      persist if outdated?
    end

    def complete
      @params[:completed_at] = Time.now
      persist
    end

    def to_serializeable
      {
        count:      count,
        total:      total,
        started_at: started_at,
        id:         @id
      }.merge(params)
    end

    private
    def persist
      @store.persist(scope, id, to_serializeable)
      @persisted_at = Time.now
    end

    def outdated?
      (@started_at - @interval) > @persisted_at
    end
  end
end
