# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "centurion/version"

Gem::Specification.new do |s|
  s.name        = "centurion"
  s.version     = Centurion::VERSION
  s.authors     = ["Jack Danger Canty"]
  s.email       = ["email@jackcanty.com"]
  s.homepage    = "http://github.com/JackDanger/centurion"
  s.summary     = %q{Monitor your Ruby project's pain}
  s.description = %q{Monitor the pain of each Ruby method in your source code}

  s.rubyforge_project = "centurion"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  s.add_development_dependency 'rake'
  s.add_development_dependency 'haml'
  s.add_development_dependency 'watchr'
  s.add_development_dependency 'rspec'
  s.add_runtime_dependency 'flog'
  s.add_runtime_dependency 'clip'
  s.add_runtime_dependency 'rack', '1.4.0'
  s.add_runtime_dependency 'flay'
  s.add_runtime_dependency 'grit'
  s.add_runtime_dependency 'json'
  s.add_runtime_dependency 'riak-client'
end
