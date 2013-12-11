module Progressrus
  class Tick
    def initialize(params)
      @params = params
    end

    def id
      @params[:id]
    end

    def name
      @params[:name] || "#{@params[:scope].join(":")}:#{@params[:id]}"
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

    def completed?
      completed_at
    end

    def completed_at
      completed = @params[:completed_at]
      return completed.to_time if completed.respond_to?(:to_time)
      completed
    end

    def elapsed
      # Make absolutely sure we don't divide by zero,
      # this is extremely unlikely but..
      (Time.now - started_at.to_time) + 1e-6
    end

    def percentage
      count.to_f / total
    end

    def eta
      return nil if count.to_i == 0

      processed_per_second = (count.to_f / elapsed)
      left = (total - count)
      seconds_to_finished = left / processed_per_second
      Time.now + seconds_to_finished
    end
  end
end
