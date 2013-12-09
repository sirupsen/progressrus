require_relative '../test_helper'

class StoreRakeTest < Minitest::Unit::TestCase

  def setup
    load File.expand_path("../../../lib/tasks/store.rake", __FILE__)
  end

  def test_store_flush_should_flush_the_store
    mock = Progressrus.store = MiniTest::Mock.new
    mock.expect(:flush, true)
    Rake::Task['progressrus:store:flush'].invoke
    mock.verify
  end

end
