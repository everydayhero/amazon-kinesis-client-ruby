# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'kcl/version'

Gem::Specification.new do |spec|
  spec.name          = 'amazon-kinesis-client-ruby'
  spec.version       = Kcl::VERSION
  spec.authors       = ['Soloman Weng']
  spec.email         = ['solomanw@everydayhero.com.au']
  spec.summary       = 'Amazon Kinesis Client Library for Ruby'
  spec.description   = 'Amazon Kinesis Client Library for Ruby'
  spec.homepage      = ''
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0") + Dir['lib/jars/*']
  spec.executables   = spec.files.grep(/^bin\//) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(/^(test|spec|features)\//)
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'activesupport', '~> 4.1'
  spec.add_runtime_dependency 'aws-kclrb', '~> 1.0.0'

  spec.add_development_dependency 'bundler', '~> 1.7'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.1.0'
  spec.add_development_dependency 'rubocop', '~> 0.27.1'
  spec.add_development_dependency 'ruby-maven', '~> 3.1.1'

  spec.required_ruby_version = '~> 2.0'
end
