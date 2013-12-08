module Progressrus
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
end
