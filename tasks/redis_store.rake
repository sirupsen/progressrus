require_relative '../lib/progressrus'
require 'rake'

namespace :progressrus do
  namespace :store do
    desc "Flushes the current Progressrus.store."
    task :flush, :environment do |t, args|
      scope = *args
      raise ArgumentError.new("Must pass [scope] to progressrus:store:flush[scope(,parts)] task.") unless scope.length > 0
      Progressrus.stores.first.flush(scope) if Progressrus.stores.first
    end
  end
end
