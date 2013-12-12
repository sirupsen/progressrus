require_relative "test_helper"

class TickTest < Minitest::Unit::TestCase
  def setup
    @started_at = Time.now - 30
    @tick = Progressrus::Tick.new(count: 30, total: 100, started_at: @started_at, scope: ["walrus"], id: "what")
  end

  def test_percentage_returns_percentage_completed
    assert_equal 0.30, @tick.percentage
  end

  def test_elapsed_returns_seconds_since_started_at
    assert_equal 30, @tick.elapsed.to_i
  end

  def test_eta_returns_estimated_finish_time
    estimated_finish_time = (@started_at.strftime("%S").to_i + 100) % 60
    assert_equal estimated_finish_time, @tick.eta.strftime("%S").to_i
  end

  def test_name_returns_scope_and_id_if_not_set
    assert_equal "walrus:what", @tick.name
  end

  def test_id_returns_the_id_of_the_tick
    assert_equal "what", @tick.id
  end

  def test_eta_should_return_nil_if_count_is_zero
    tick = Progressrus::Tick.new(count: 0, total: 100, started_at: @started_at, scope: ["walrus"], id: "what")
    assert_equal nil, tick.eta
  end
end
