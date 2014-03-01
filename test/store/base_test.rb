require_relative "../test_helper"

class BaseStoreTest < Minitest::Unit::TestCase
  def setup
    @base = Progressrus::Store::Base.new
  end

  def test_persist_raises_not_implemented
    assert_raises Progressrus::Store::NotImplementedError do
      @base.persist(nil)
    end
  end

  def test_scope_raises_not_implemented
    assert_raises Progressrus::Store::NotImplementedError do
      @base.scope(nil)
    end
  end

  def test_find_raises_not_implemented
    assert_raises Progressrus::Store::NotImplementedError do
      @base.find(nil, nil)
    end
  end

  def test_flush_raises_not_implemented
    assert_raises Progressrus::Store::NotImplementedError do
      @base.flush(nil)
    end
  end
end
