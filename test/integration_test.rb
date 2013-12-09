require_relative "test_helper"

class IntegrationTest < Minitest::Unit::TestCase
  def setup
    Progressrus.store = Progressrus::Store::Redis.new
    @progresser = Progressrus::Progresser.new(scope: ["walrus"], total: 20)
  end

  def teardown
    Progressrus.store.flush
  end

  def test_create_tick_and_see_status_in_redis
    @progresser.tick

    ticks = Progressrus.scope(["walrus"]).values

    assert_equal 1, ticks.length

    tick = ticks.first
    assert_equal 20, tick.total
    assert_equal 1, tick.count
  end

  def test_create_multiple_ticks_and_see_them_in_redis
    @progresser.tick

    progresser2 = Progressrus::Progresser.new(scope: ["walrus"], total: 50)
    progresser2.tick

    ticks = Progressrus.scope(["walrus"]).values

    assert_equal 2, ticks.length

    assert_equal [20, 50], ticks.map(&:total).sort
    assert_equal [1,1], ticks.map(&:count)
  end
end
