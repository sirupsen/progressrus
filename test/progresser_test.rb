require_relative "test_helper"

class ProgresserTest < Minitest::Unit::TestCase
  def setup
    Progressrus.store = Progressrus::Store::Redis.new
    @progresser = Progressrus::Progresser.new(scope: ["walrus"], total: 20)
    @progresser.store.stubs(:persist).returns(true)
  end

  def test_tick_increments_by_one_with_no_arguments
    assert_equal 0, @progresser.count

    @progresser.tick

    assert_equal 1, @progresser.count
  end

  def test_tick_calls_persistency_layer_on_first_tick
    @progresser.store.expects(:persist).once
    @progresser.tick
  end

  def test_tick_calls_persistence_layer_once_on_two_fast_calls
    @progresser.store.expects(:persist).once
    @progresser.tick
    @progresser.tick

    assert_equal 2, @progresser.count
  end

  def test_tick_generates_random_id_if_not_supplied
    assert_instance_of String, @progresser.id
  end

  def test_tick_sets_supplied_id
    progresser = Progressrus::Progresser.new(id: 1239)
    assert_equal "1239", progresser.id
  end
end
