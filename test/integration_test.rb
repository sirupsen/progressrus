require_relative "test_helper"

class IntegrationTest < Minitest::Test
  def setup
    @progress = Progressrus.new(scope: "walrus", total: 20)
  end

  def teardown
    Progressrus.stores[:redis].flush(@progress.scope)
  end

  def test_create_tick_and_see_status_in_redis
    @progress.tick

    ticks = Progressrus.scope(["walrus"]).values

    assert_equal 1, ticks.length

    tick = ticks.first
    assert_equal 20, tick.total
    assert_equal 1, tick.count
  end

  def test_setting_total_after_persist_persists_total
    progress = Progressrus.new(scope: ["walrus"], total: 0, persist: true, id: '123')
    assert_equal 0, progress.total
    progress.total = 20
    progress = Progressrus.find(["walrus"], '123')
    assert_equal 20, progress.total
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
    assert_equal a.size, ticks.first.count
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

    assert_equal 0, ticks.first.count
    assert_instance_of Time, ticks.first.failed_at
  end

  def test_unknown_count
    progress = Progressrus.new(id: "omg", scope: ["walrus"], total: nil)
    progress.tick

    progress = Progressrus.find(["walrus"], "omg")
    assert_nil progress.total
    assert_nil progress.eta
    assert_nil progress.percentage
  end
end
