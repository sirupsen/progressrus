require_relative "../test_helper"

class RedisStoreTest < Minitest::Unit::TestCase
  def setup
    @store = Progressrus::Store::Redis.new
    Progressrus.store = @store
    @progress = Progressrus::Progresser.new(
      scope: ["walrus", "1234"],
      id: "oemg",
      total: 100,
      name: "oemg-test"
    )

    @second_progress = Progressrus::Progresser.new(
      scope: ["walrus", "1234"],
      id: "narwhal",
      total: 50,
      name: "oemg-test-2"
    )
  end

  def teardown
    @store.flush(@progress.scope)
  end

  def test_persist_persists_a_progress_object
    @store.persist(@progress)
    tick = @store.scope(@progress.scope)["oemg"]

    assert_instance_of Progressrus::Tick, tick
    assert_equal 0, tick.count
    assert_equal 100, tick.total
    assert_equal "oemg-test", tick.params[:name]
  end

  def test_persist_twice_updates_object
    @progress.stubs(:count).returns(31)
    @store.persist(@progress)

    tick = @store.scope(@progress.scope)["oemg"]

    assert_equal 31, tick.count
  end

  def test_expire_key
    @store.options[:expire] = 1
    @store.persist(@progress)
    sleep 1
    assert @store.scope(@progress.scope).empty?,
      "Expected key to have expired after 1 second."
  end

  def test_flush_entire_scope
    @store.persist(@progress)
    assert @store.scope(@progress.scope).has_key?("oemg")

    @store.persist(@second_progress)
    assert @store.scope(@second_progress.scope).has_key?("narwhal")

    @store.flush(@progress.scope)
    refute @store.scope(@progress.scope).has_key?("oemg")
    refute @store.scope(@progress.scope).has_key?("narwhal")
  end

  def test_flush_single_job
    @store.persist(@progress)
    assert @store.scope(@progress.scope).has_key?("oemg")

    @store.persist(@second_progress)
    assert @store.scope(@second_progress.scope).has_key?("narwhal")

    @store.flush(@progress.scope, "narwhal")
    refute @store.scope(@second_progress.scope).has_key?("narwhal")
    assert @store.scope(@progress.scope).has_key?("oemg")
  end

  def test_get_should_fetch_by_scope_and_id
    @store.persist(@progress)

    progresser = @store.get(@progress.scope, 'oemg')

    assert_instance_of Progressrus::Progresser, progresser
    assert_equal 0, progresser.count
    assert_equal 100, progresser.total
    assert_equal 'oemg', progresser.id
  end
end
