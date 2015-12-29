# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'pub_sub/version'

Gem::Specification.new do |spec|
  spec.name          = 'pub_sub'
  spec.version       = PubSub::VERSION
  spec.authors       = ['Chris Nelson', 'Eugene Mirkin']
  spec.email         = ['cnelson@au.westfield.com', 'emirkin@us.westfield.com']

  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com' to prevent pushes to rubygems.org, or delete to allow pushes to any server."
  end

  spec.summary       = 'Encapsulates common Pub/Sub logic for communication between services.'
  spec.homepage      = 'https://www.github.com/westfield/pub_sub'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'aws-sdk', '~> 2'
  spec.add_dependency 'activesupport', '~> 4.2'
  spec.add_dependency 'cb2', '~> 0.0.3'
  spec.add_dependency 'redis', '~> 3.2'
  spec.add_dependency 'faraday'
  spec.add_dependency 'colorize'
  spec.add_dependency 'redlock'

  spec.add_development_dependency 'bundler', '~> 1.8'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.2.0'
end
