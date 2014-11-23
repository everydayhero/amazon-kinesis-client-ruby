require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'
require 'rubygems/tasks'
require 'maven/ruby/maven'

RSpec::Core::RakeTask.new :spec do |spec|
  spec.rspec_opts = '--format documentation --color'
end

RuboCop::RakeTask.new

Gem::Tasks::Build::Gem.new do |build|
  mvn = Maven::Ruby::Maven.new
  mvn.exec 'generate-sources', '-f', 'pom.xml'
end
