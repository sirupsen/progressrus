require 'json'
require 'securerandom'
require 'redis'
require_relative "store/base"
require_relative "store/redis"
require_relative "progresser"
require_relative "tick"

module Progressrus
  def self.scope(scope, store = @@store)
    store.scope(scope)
  end

  def self.store=(store = Redis::Base.new)
    @@store = store
  end

  def self.store
    @@store
  end
end
