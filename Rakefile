begin
  require 'rake/clean'
  require 'cucumber/rake/task'

  CLEAN.include('pkg/', 'tmp/')
  CLOBBER.include('Gemfile.lock')

  Cucumber::Rake::Task.new(:features)

  task :default => :features
rescue LoadError
end

require 'bundler/gem_tasks'
