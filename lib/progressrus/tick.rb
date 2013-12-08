module Progressrus
  class Tick
    def initialize(values)
      @values = values
    end

    def count
      @values[:count]
    end

    def total
      @values[:total]
    end

    def started_at
      @values[:started_at]
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
end
