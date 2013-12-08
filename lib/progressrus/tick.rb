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
      # Make absolutely sure we don't divide by zero,
      # this is extremely unlikely but..
      (Time.now - started_at) + 1e-6
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
