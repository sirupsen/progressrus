require_relative "test_helper"

class ProgressrusTest < Minitest::Unit::TestCase
  def setup
    @progress = Progressrus.new(scope: :progressrus, total: 100)
  end

  def teardown
    Progressrus.stores.default!
  end

  def test_defaults_to_redis_store
    assert_instance_of Progressrus::Store::Redis, Progressrus.stores.first
  end

  def test_add_to_store
    Progressrus.stores << Progressrus::Store::Base.new
    assert_instance_of Progressrus::Store::Base, Progressrus.stores[1]
  end

  def test_scope_should_initialize_with_symbol_or_string
    progressrus = Progressrus.new(scope: :walrus)
    assert_equal ['walrus'], progressrus.scope
  end

  def test_scope_should_initialize_with_array
    progressrus = Progressrus.new(scope: ['walruses', 1])
    assert_equal ['walruses', '1'], progressrus.scope
  end

  def test_initialize_with_name_should_use_name
    progressrus = Progressrus.new(name: 'Wally')
    assert_equal 'Wally', progressrus.name
  end

  def test_initialize_without_name_should_use_id
    progressrus = Progressrus.new(id: 'oemg')
    assert_equal 'oemg', progressrus.name
  end

  def test_initialize_with_persist
    Progressrus.any_instance.expects(:persist).with(force: true).once
    progressrus = Progressrus.new(persist: true)
  end

  def test_tick_should_set_started_at_if_not_already_set_and_tick_greater_than_zero
    @progress.tick
    assert @progress.started_at
  end

  def test_tick_should_not_set_started_at_if_zero_but_persist
    @progress.expects(:persist).once
    @progress.tick(0)
    refute @progress.started_at
  end

  def test_tick_should_increment_count_by_one_if_not_specified
    @progress.tick
    assert_equal 1, @progress.count
  end

  def test_tick_should_increment_count
    @progress.tick(50)
    assert_equal 50, @progress.count
  end

  def test_error_should_not_call_tick
    @progress.expects(:tick).never
    @progress.error
  end

  def test_error_should_increment_error_count_by_one_if_amount_not_specified
    @progress.error
    assert_equal 1, @progress.error_count
  end

  def test_error_should_increment_error_count
    @progress.error(25)
    assert_equal 25, @progress.error_count
  end

  def test_eta_should_return_nil_if_no_count
    progress = Progressrus.new
    assert_equal nil, progress.eta
  end

  def test_eta_should_return_time_in_future_based_on_time_elapsed
    time = Time.now
    @progress.tick(10, now: time - 10)

    eta = @progress.eta(now: time)

    assert_equal time + 90, eta
    assert_instance_of Time, eta
  end

  def test_percentage_should_return_the_percentage_as_a_fraction
    @progress.tick(50)

    assert_equal 0.5, @progress.percentage
  end

  def test_percentage_with_no_count_should_be_zero
    assert_equal 0, @progress.percentage
  end

  def test_percentage_should_be_able_to_return_more_than_1
    @progress.tick(120)

    assert_equal 1.2, @progress.percentage
  end

  def test_percentage_should_be_0_if_total_0
    assert_equal 0, @progress.percentage
  end

  def test_elapsed_should_return_the_delta_between_now_and_started_at
    time = Time.now
    @progress.tick(10, now: time - 10)

    elapsed = @progress.elapsed(now: time)

    assert_equal 10, elapsed
  end

  def test_to_serializeable_set_total_to_1_if_no_total
    @progress.instance_variable_set(:@total, nil)
    assert_equal 1, @progress.to_serializeable[:total]
  end

  def test_total_when_total_is_nil_is_1
    @progress.instance_variable_set(:@total, nil)
    assert_equal 1, @progress.total
  end

  def test_to_serializeable_should_return_a_hash_of_options
    progress = Progressrus.new(
      name: 'Wally',
      id: 'oemg',
      scope: ['walruses', 'forall'],
      total: 100,
      params: { job_id: 'oemg' }
    )

    serialization = {
      name: 'Wally',
      id: 'oemg',
      scope: ['walruses', 'forall'],
      total: 100,
      params: { job_id: 'oemg' },
      started_at: nil,
      completed_at: nil,
      failed_at: nil,
      count: 0,
      error_count: 0,
      expires_at: nil
    }

    assert_equal serialization, progress.to_serializeable
  end

  def test_complete_should_set_completed_at_and_persist
    now = Time.now
    @progress.expects(:persist)

    @progress.complete(now: Time.now)

    assert_equal now.to_i, @progress.completed_at.to_i
  end

  def test_should_not_be_able_to_set_total_to_0
    assert_raises ArgumentError do
      @progress.total = 0
    end
  end

  def test_should_not_be_able_to_set_total_to_a_negative_number
    assert_raises ArgumentError do
      @progress.total = -1
    end
  end

  def test_persist_yields_persist_to_each_store
    mysql = mock()
    mysql.expects(:persist).once

    redis = Progressrus.stores.first
    redis.expects(:persist).once

    Progressrus.stores << mysql

    @progress.tick
  end

  def test_tick_and_complete_dont_raise_if_store_is_unavailable
    store = Progressrus.stores.first
    store.redis.expects(:hset).at_least_once.raises(::Redis::BaseError)
    @progress.tick
    @progress.complete
  end

  def test_should_not_be_able_to_initialize_with_total_0
    assert_raises ArgumentError do
      Progressrus.new(total: 0)
    end
  end

  def test_should_not_be_able_to_initialize_with_total_as_a_negative_number
    assert_raises ArgumentError do
      Progressrus.new(total: -1)
    end
  end

  def test_date_fields_should_deserialize_properly
    @progress.tick(1)
    @progress.complete
    progress = Progressrus.find(@progress.scope, @progress.id)
    assert_instance_of Time, progress.started_at
    assert_instance_of Time, progress.completed_at
  end


  def test_default_scope_on_first
    Progressrus.stores.clear

    mysql = mock()
    redis = mock()

    Progressrus.stores << mysql
    Progressrus.stores << redis

    mysql.expects(:scope).once
    redis.expects(:scope).never

    Progressrus.scope(["oemg"])
  end

  def test_support_scope_last
    Progressrus.stores.clear

    mysql = mock()
    redis = mock()

    Progressrus.stores << mysql
    Progressrus.stores << redis

    mysql.expects(:scope).never
    redis.expects(:scope).once

    Progressrus.scope(["oemg"], store: :last)
  end

  def test_support_scope_by_name
    Progressrus.stores.clear

    mysql = mock()
    redis = mock()

    mysql.stubs(:name).returns(:mysql)
    redis.stubs(:name).returns(:redis)

    Progressrus.stores << mysql
    Progressrus.stores << redis

    mysql.expects(:scope).never
    redis.expects(:scope).once

    Progressrus.all(["oemg"], store: :redis)
  end

  def test_find_should_find_a_progressrus_by_scope_and_id
    @progress.tick
    progress = Progressrus.find(@progress.scope, @progress.id)

    assert_instance_of Progressrus, progress
  end

  def test_completed_should_set_started_at_if_never_ticked
    refute @progress.started_at
    @progress.complete

    assert_instance_of Time, @progress.started_at
    assert_instance_of Time, @progress.completed_at
  end

  def test_able_to_set_count
    @progress.count = 100
    assert_equal 100, @progress.count
  end

  def test_call_persist_after_setting_count
    @progress.expects(:persist).once

    @progress.count = 100
  end

  def test_set_started_at_if_not_set
    @progress.instance_variable_set(:@started_at, nil)
    @progress.count = 100

    assert_instance_of Time, @progress.started_at
  end

  def test_flush_should_flush_a_progressrus_by_scope_and_id
    @progress.tick

    Progressrus.flush(@progress.scope, @progress.id)

    assert_nil Progressrus.find(@progress.scope, @progress.id)
  end

  def test_flush_should_flush_a_progressrus_scope_without_an_id
    @progress.tick

    Progressrus.flush(@progress.scope)

    assert_equal({}, Progressrus.scope(@progress.scope))
  end

  def test_flush_instance_of_progressrus
    @progress.tick

    @progress.flush

    assert_nil Progressrus.find(@progress.scope, @progress.id)
  end

  def test_call_with_progress_on_enumerable_as_final_in_chain
    a = [1,2,3]
    Progressrus.any_instance.expects(:tick).times(a.count)

    b = []
    a.each.with_progress do |number|
      b << number
    end

    assert_equal a, b
  end

  def test_call_with_progress_on_enumerable_in_middle_of_chain
    a = [1,2,3]
    Progressrus.any_instance.expects(:tick).times(a.count)

    b = a.each.with_progress.map { |number| number }

    assert_equal a, b
  end

  def test_fail_should_set_failed_at_and_persist
    now = Time.now
    @progress.expects(:persist)

    @progress.fail(now: now)

    assert_equal now.to_i, @progress.failed_at.to_i
  end

  def test_status_returns_completed_when_job_is_completed
    @progress.complete

    assert_equal :completed, @progress.status
  end

  def test_status_returns_failed_when_job_has_failed
    @progress.fail

    assert_equal :failed, @progress.status
  end

  def test_status_returns_running_when_job_hasnt_failed_or_completed
    @progress.tick

    assert_equal :running, @progress.status
  end

  def test_status_returns_started_when_job_hasnt_ticked
    assert_equal :started, @progress.status
  end

  def test_running_returns_true_when_job_has_ticked
    @progress.tick

    assert @progress.running?
  end

  def test_expired_returns_false_when_nil
    progress = Progressrus.new(
      id: 'oemg',
      scope: ['walruses', 'forall']
    )

    refute progress.expired?
  end

  def test_expired_returns_true_if_expires_at_in_past
    time = Time.now
    progress = Progressrus.new(
      id: 'oemg',
      scope: ['walruses', 'forall'],
      expires_at: time - 3600
    )

    assert progress.expired?(now: time)
  end

  def test_expired_returns_false_if_expires_at_in_the_future
    time = Time.now
    progress = Progressrus.new(
      id: 'oemg',
      scope: ['walruses', 'forall'],
      expires_at: time + 3600
    )

    refute progress.expired?(now: time)
  end
end
