# -*- encoding: utf-8 -*-
require File.expand_path(File.join('..', 'lib', 'omniauth', 'samaritan', 'version'), __FILE__)

Gem::Specification.new do |gem|
  gem.add_dependency 'omniauth', '~> 1.0'

  gem.authors       = ["Doug Bradbury", "Ben Voss"]
  gem.email         = ["smi@8thlight.com", "chandlerroth@smchcn.net"]
  gem.description   = %q{A Samaritan OAuth2 strategy for OmniAuth 1.x.}
  gem.summary       = %q{A Samaritan OAuth2 strategy for OmniAuth 1.x}
  gem.homepage      = "http://docs.samaritanministries.org/ruby-oauth/"
  gem.licenses      = ['MIT']

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {spec}/*`.split("\n")
  gem.name          = "omniauth-samaritan"
  gem.require_paths = ["lib"]
  gem.version       = OmniAuth::Samaritan::VERSION

  gem.add_runtime_dependency 'omniauth-oauth2', '~> 1.1', '>= 1.1.2'

  gem.add_development_dependency 'rspec', '~> 2.6.0', '>= 2.6.0'
  gem.add_development_dependency 'rake', '~> 0'
end
