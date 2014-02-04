require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

namespace :spec do
  RSpec::Core::RakeTask.new(:unit) do |t|
    t.pattern = 'spec/unit/*_spec.rb'
  end
end

desc 'Run unit specs'
task :default => 'spec:unit'
