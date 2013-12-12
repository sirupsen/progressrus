require 'json'
require 'securerandom'
require 'redis'
require_relative "progressrus/store/base"
require_relative "progressrus/store/redis"
require_relative "progressrus/progress"
require_relative "progressrus/tick"

module Progressrus
  def self.scope(scope, store = @@store)
    store.scope(scope)
  end

  def self.get(scope, id, store = @@store)
    store.get(scope, id)
  end

  def self.store=(store = Redis::Base.new)
    @@store = store
  end

  def self.store
    @@store if defined?(@@store)
  end
end

require 'progressrus/railtie' if defined?(Rails)
