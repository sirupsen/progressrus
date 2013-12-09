module Progressrus
  class Railtie < Rails::Railtie
    rake_tasks do
      load File.expand_path('../../../tasks/store.rake', __FILE__)
    end
  end
end
