require 'bundler/gem_tasks'
require 'rake/testtask'

task :default => :test

Rake::TestTask.new do |t|
  t.libs << ['lib', 'test']
  t.pattern = "test/test*.rb"
end
