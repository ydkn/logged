# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'logged/version'

Gem::Specification.new do |spec|
  rails_version      = '>= 4.0', '< 5.0'

  spec.name          = 'logged'
  spec.version       = Logged::VERSION
  spec.authors       = ['Florian Schwab']
  spec.email         = ['me@ydkn.de']
  spec.summary       = %q(Better logging for rails)
  spec.homepage      = ''
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler',      '~> 1.7'
  spec.add_development_dependency 'rake',         '~> 10.0'
  spec.add_development_dependency 'rspec',        '~> 3.1'
  spec.add_development_dependency 'actionpack',   rails_version
  spec.add_development_dependency 'actionview',   rails_version
  spec.add_development_dependency 'actionmailer', rails_version
  spec.add_development_dependency 'activerecord', rails_version

  spec.add_dependency 'railties', rails_version
end
