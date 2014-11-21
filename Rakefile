require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

RSpec::Core::RakeTask.new :spec do |spec|
  spec.rspec_opts = '--format documentation --color'
end

RuboCop::RakeTask.new
