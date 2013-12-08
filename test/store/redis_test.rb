require_relative "../test_helper"

class RedisStoreTest < Minitest::Unit::TestCase
  def setup
    @store = Progressrus::Store::Redis.new
    Progressrus.store = @store
    @progress = Progressrus::Progresser.new(
      {scope: ["walrus", "1234"],
      id: "oemg",
      total: 100},
      { name: "oemg-test" }
    )
  end

  def teardown
    @store.flush
  end

  def test_persist_persists_a_progress_object
    @progress.persist
    tick = @store.scope(@progress.scope)["oemg"]

    assert_instance_of Progressrus::Tick, tick
    assert_equal 0, tick.count
    assert_equal 100, tick.total
    assert_equal "oemg-test", tick.params[:name]
  end

  def test_persist_twice_updates_object
    @progress.stubs(:count).returns(31)
    @progress.persist

    tick = @store.scope(@progress.scope)["oemg"]

    assert_equal 31, tick.count
  end

  def test_expire_key
    @store.expire = 1
    @progress.persist
    sleep 1
    assert @store.scope(@progress.scope).empty?, 
      "Expected key to have expired after 1 second."
  end
end
