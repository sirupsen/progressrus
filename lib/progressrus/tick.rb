module Progressrus
  class Tick
    def initialize(params)
      @params = params
    end

    def count
      @params[:count]
    end

    def total
      @params[:total]
    end

    def started_at
      @params[:started_at]
    end

    def params
      @params
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
