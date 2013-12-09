require "bundler/gem_tasks"
require 'rake/testtask'

Dir.glob('lib/tasks/*.rake').each { |r| load r}

task :default => :test

desc 'Run the test suite.'

Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.libs << 'test'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
  t.warning = false
end
