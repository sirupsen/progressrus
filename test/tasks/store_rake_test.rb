require_relative '../test_helper'

class StoreRakeTest < Minitest::Unit::TestCase

  def setup
    load File.expand_path("../../../lib/tasks/store.rake", __FILE__)
  end

  def test_store_flush_should_flush_the_store
    Progressrus.store.expects(:flush)
    Rake::Task['progressrus:store:flush'].invoke
  end

end
