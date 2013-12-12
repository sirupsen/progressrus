require_relative "../test_helper"

class RedisStoreTest < Minitest::Unit::TestCase
  def setup
    @store = Progressrus::Store::Redis.new
    Progressrus.store = @store
    @progress = Progressrus::Progress.new(
      scope: ["walrus", "1234"],
      id: "oemg",
      total: 100,
      name: "oemg-test"
    )

    @second_progress = Progressrus::Progress.new(
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

  def test_scope_should_fetch_all_ticks_by_scope
    @store.persist(@progress)
    @store.persist(@second_progress)

    ticks = @store.scope(@progress.scope)

    assert_equal 2, ticks.length
    assert_equal ['narwhal','oemg'], ticks.keys.sort!
    assert_instance_of Progressrus::Tick, ticks['oemg']
    assert_instance_of Progressrus::Tick, ticks['narwhal']
  end

  def test_find_should_fetch_by_scope_and_id
    @store.persist(@progress)

    progress = @store.find(@progress.scope, 'oemg')

    assert_instance_of Progressrus::Progress, progress
    assert_equal 0, progress.count
    assert_equal 100, progress.total
    assert_equal 'oemg', progress.id
  end

  def test_all_should_fetch_by_scope_and_id
    @store.persist(@progress)
    @store.persist(@second_progress)

    progresses = @store.all(@progress.scope)

    assert_equal 2, progresses.length
    progresses.sort_by!(&:id)
    assert_equal 'narwhal', progresses[0].id
    assert_equal 'oemg', progresses[1].id
  end
end
