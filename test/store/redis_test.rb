require_relative "../test_helper"

class RedisStoreTest < Minitest::Unit::TestCase
  def setup
    @store = Progressrus::Store::Redis.new
    @progress = stub(
      scope: ["walrus", "1234"],
      id: "oemg",
      count: 30,
      total: 100,
      started_at: Time.now - 10
    )
  end

  def teardown
    @store.flush
  end

  def test_persist_persists_a_progress_object
    @store.persist(@progress)
    tick = @store.scope(@progress.scope)["oemg"]

    assert_instance_of Progressrus::Tick, tick
    assert_equal 30, tick.count
    assert_equal 100, tick.total
  end

  def test_persist_twice_updates_object
    @store.persist(@progress)
    @progress.stubs(:count).returns(31)
    @store.persist(@progress)

    tick = @store.scope(@progress.scope)["oemg"]

    assert_equal 31, tick.count
  end

  def test_expire_key
    @store.expire = 1
    @store.persist(@progress)
    sleep 1
    assert @store.scope(@progress.scope).empty?, 
      "Expected key to have expired after 1 second."
  end
end
