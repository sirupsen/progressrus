require_relative "../test_helper"

class RedisStoreTest < Minitest::Test
  class PrefixClass
    def self.call(scope)
      "custom_prefix:#{scope.join(':')}"
    end
  end
  def setup
  	@scope = ["walrus", "1234"]
    @progress = Progressrus.new(
      scope: @scope,
      id: "oemg",
      total: 100,
      name: "oemg-name"
    )

  	@another_progress = Progressrus.new(
      scope: @scope,
      id: "oemg-two",
      total: 100,
      name: "oemg-name-two"
    )

    @redis = ::Redis.new(host: ENV["PROGRESSRUS_REDIS_HOST"] || "localhost")

    @store = Progressrus::Store::Redis.new(@redis)
  end

  def teardown
    @store.flush(@scope)
  end

  def test_prefix_can_be_a_proc
    store = Progressrus::Store::Redis.new(@redis, prefix: PrefixClass)
    store.persist(@progress)
    refute_empty(@redis.hgetall('custom_prefix:walrus:1234'))
  end

  def test_persist_should_set_key_value_if_outdated
  	@store.persist(@progress)

  	assert_equal 'oemg', @store.find(['walrus', '1234'], 'oemg').id
  end

  def test_persist_should_not_set_key_value_if_not_outdated
  	@store.redis.expects(:hset).once

  	@store.persist(@progress)
  	@store.persist(@progress)
  end

  def test_scope_should_return_progressruses_indexed_by_id
    @store.persist(@progress)
    @store.persist(@another_progress)
    actual = @store.scope(@scope)

    assert_equal @progress.id, actual['oemg'].id
    assert actual['oemg'].persisted?
    assert_equal @another_progress.id, actual['oemg-two'].id
    assert actual['oemg-two'].persisted?
  end

  def test_scope_should_return_an_empty_hash_if_nothing_is_found
  	assert_equal({}, @store.scope(@scope))
  end

  def test_find_should_return_a_single_progressrus_for_scope_and_id
    @store.persist(@progress)
    stored_progress = @store.find(@scope, 'oemg')
    assert_equal @progress.id, stored_progress.id
    assert stored_progress.persisted?
  end

  def test_find_should_return_nil_if_nothing_is_found
  	assert_nil @store.find(@scope, 'oemg')
  end

  def test_flush_should_delete_by_scope
  	@store.persist(@progress)
  	@store.persist(@another_progress)

  	@store.flush(@scope)

  	assert_equal({}, @store.scope(@scope))
  end

  def test_flush_should_delete_by_scope_and_id
	  @store.persist(@progress)
  	@store.persist(@another_progress)

	  @store.flush(@scope, 'oemg')

  	assert_nil @store.find(@scope, 'oemg')
  	assert @store.find(@scope, 'oemg-two')
  end

  def test_initializes_name_to_redis
  	assert_equal :redis, @store.name
  end

  def test_persist_should_not_write_by_default
    @store.redis.expects(:hset).once

    @store.persist(@progress)
    @store.persist(@progress)
  end

  def test_persist_should_write_if_forced
    @store.redis.expects(:hset).twice

    @store.persist(@progress)
    @store.persist(@progress, force: true)
  end
end
