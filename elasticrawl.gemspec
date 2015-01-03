# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'elasticrawl/version'

Gem::Specification.new do |spec|
  spec.name          = 'elasticrawl'
  spec.version       = Elasticrawl::VERSION
  spec.authors       = ['Ross Fairbanks']
  spec.email         = ['ross@rossfairbanks.com']
  spec.summary       = %q{Launch AWS Elastic MapReduce jobs that process Common Crawl data.}
  spec.description   = %q{Elasticrawl is a tool for launching AWS Elastic MapReduce jobs that process Common Crawl data.}
  spec.homepage      = 'https://github.com/rossf7/elasticrawl'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'activerecord', '~> 4.2'
  spec.add_dependency 'activesupport', '~> 4.2'
  spec.add_dependency 'aws-sdk', '~> 1.60'
  spec.add_dependency 'elasticity', '~> 4.0'
  spec.add_dependency 'highline', '~> 1.6'
  spec.add_dependency 'sqlite3', '~> 1.3'
  spec.add_dependency 'thor', '~> 0.19'

  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rspec', '~> 3.1'
  spec.add_development_dependency 'database_cleaner', '~> 1.3.0'
  spec.add_development_dependency 'shoulda-matchers', '~> 2.7.0'
end
