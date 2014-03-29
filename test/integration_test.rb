require_relative "test_helper"

class IntegrationTest < Minitest::Unit::TestCase
  def setup
    @progress = Progressrus.new(scope: "walrus", total: 20)
  end

  def teardown
    Progressrus.stores.first.flush(@progress.scope)
  end

  def test_create_tick_and_see_status_in_redis
    @progress.tick

    ticks = Progressrus.scope(["walrus"]).values

    assert_equal 1, ticks.length

    tick = ticks.first
    assert_equal 20, tick.total
    assert_equal 1, tick.count
  end

  def test_create_multiple_ticks_and_see_them_in_redis
    @progress.tick

    progress2 = Progressrus.new(scope: ["walrus"], total: 50)
    progress2.tick

    ticks = Progressrus.scope(["walrus"]).values

    assert_equal 2, ticks.length

    assert_equal [20, 50], ticks.map(&:total).sort
    assert_equal [1,1], ticks.map(&:count)
  end

  def test_tick_on_enumerable
    a = (0..10)
    b = a.with_progress(scope: "walrus").map(&:to_i)

    ticks = Progressrus.scope(["walrus"]).values

    assert_equal a.to_a, b
    assert_equal 1, ticks.length
    assert_equal a.size, ticks.first.total
    assert_instance_of Time, ticks.first.completed_at
  end

  def test_tick_on_enumerable_calls_fail_on_exception
    a = (0..10)

    assert_raises ArgumentError do
      a.with_progress(scope: "walrus").each do
        raise ArgumentError
      end
    end

    ticks = Progressrus.scope(["walrus"]).values
    assert_instance_of Time, ticks.first.failed_at
  end
end
