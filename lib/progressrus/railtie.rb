module Progressrus
  class Railtie < Rails::Railtie
    rake_tasks do
      load "tasks/store"
    end
  end
end
