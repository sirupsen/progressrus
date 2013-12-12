require_relative "test_helper"

class ProgressTest < Minitest::Unit::TestCase
  def setup
    Progressrus.store = Progressrus::Store::Redis.new
    @progress = Progressrus::Progress.new(scope: ["walrus"], total: 20)
  end

  def teardown
    Progressrus.store.flush(@progress.scope)
  end

  def test_tick_increments_by_one_with_no_arguments
    assert_equal 0, @progress.count

    @progress.tick

    assert_equal 1, @progress.count
  end

  def test_tick_calls_persistency_layer_on_first_tick
    @progress.store.expects(:persist).once
    @progress.tick
  end

  def test_tick_calls_persistence_layer_once_on_two_fast_calls
    @progress.store.expects(:persist).once
    @progress.tick
    @progress.tick

    assert_equal 2, @progress.count
  end

  def test_tick_generates_random_id_if_not_supplied
    assert_instance_of String, @progress.id
  end

  def test_tick_sets_supplied_id
    progress = Progressrus::Progress.new(id: 1239, scope: ["wut"])
    assert_equal "1239", progress.id
  end

  def test_complete_sets_completed_at
    refute @progress.completed_at

    @progress.complete

    assert_instance_of Time, @progress.completed_at
  end

  def test_complete_forces_a_persist
    @progress.expects(:persist)
    @progress.complete
  end

  def test_to_serializeable_raises_if_total_is_not_set
    @progress.total = nil

    assert_raises ArgumentError do
      @progress.to_serializeable
    end
  end
end
