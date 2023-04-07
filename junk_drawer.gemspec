# frozen_string_literal: true

require_relative 'lib/junk_drawer/version'

Gem::Specification.new do |spec|
  spec.name          = 'junk_drawer'
  spec.version       = JunkDrawer::VERSION
  spec.authors       = ['Robert Fletcher']
  spec.email         = ['lobatifricha@gmail.com']

  spec.summary       = 'random useful Ruby utilities'
  spec.homepage      = 'https://github.com/thread-pond/junk_drawer'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^spec/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.1'

  spec.add_runtime_dependency 'ruby2_keywords', '~> 0.0.2'
  spec.add_development_dependency 'guard', '~> 2.14'
  spec.add_development_dependency 'guard-rspec', '~> 4.7'
  spec.add_development_dependency 'guard-rubocop', '~> 1.2'
  spec.add_development_dependency 'pg', '~> 0.20'
  spec.add_development_dependency 'pry', '~> 0.10'
  spec.add_development_dependency 'pry-byebug', '~> 3.6.0'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '1.49.0'
  spec.add_development_dependency 'rubocop-rspec', '~> 1.15.0'
  spec.add_development_dependency 'simplecov', '~> 0.14'
  spec.add_development_dependency 'with_model', '~> 2.0'
end
