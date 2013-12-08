require_relative "test_helper"

class TickTest < Minitest::Unit::TestCase
  def setup
    @started_at = Time.now - 30
    @tick = Progressrus::Tick.new(count: 30, total: 100, started_at: @started_at)
  end

  def test_percentage_returns_percentage_completed
    assert_equal 0.30, @tick.percentage
  end

  def test_elapsed_returns_seconds_since_started_at
    assert_equal 30, @tick.elapsed
  end

  def test_eta_returns_estimated_finish_time
    estimated_finish_time = (@started_at.strftime("%S").to_i + 100) % 60
    assert_equal estimated_finish_time, @tick.eta.strftime("%S").to_i
  end
end
