require_relative '../progressrus'
require 'rake'

namespace :progressrus do
  namespace :store do
    desc "Flushes the current Progressrus.store"
    task :flush do
      Progressrus.store.flush if Progressrus.store
    end
  end
end
