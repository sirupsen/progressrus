require_relative '../test_helper'

class StoreRakeTest < Minitest::Unit::TestCase
  def setup
    load File.expand_path("../../../tasks/redis_store.rake", __FILE__)
    Rake::Task.define_task(:environment)
  end

  def test_store_flush_should_flush_the_store_with_mutli_key_scopes
    Progressrus::Store::Redis.any_instance.expects(:flush).with([1, 'test'])
    Rake::Task['progressrus:store:flush'].invoke(1,'test')
  end
end
