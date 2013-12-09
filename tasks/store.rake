require_relative '../lib/progressrus'
require 'rake'

namespace :progressrus do
  namespace :store do
    desc "Flushes the current Progressrus.store."
    task :flush, [:scope] do |t, args|
      raise ArgumentError.new("Must pass [scope] to progressrus:store:flush[scope] task.") unless args[:scope]
      debugger
      Progressrus.store.flush(args[:scope]) if Progressrus.store
    end
  end
end
