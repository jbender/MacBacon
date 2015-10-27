# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'mac_bacon/version'

Gem::Specification.new do |spec|
  spec.name     = 'mac_bacon'
  spec.version  = Bacon::VERSION
  spec.platform = Gem::Platform::RUBY
  spec.author   = 'Eloy Durán'
  spec.email    = 'eloy.de.enige@gmail.com'
  spec.homepage = 'https://github.com/alloy/MacBacon'
  spec.license  = 'MIT'

  spec.summary     = 'a small RSpec clone for MacRuby'
  spec.description = <<-EOF
Bacon is a small RSpec clone weighing less than 350 LoC but
nevertheless providing all essential features.

This MacBacon fork differs with regular Bacon in that it operates
properly in a NSRunloop based environment. I.e. MacRuby/Objective-C.

https://github.com/alloy/MacBacon
EOF

  spec.files            = `git ls-files`.split($/)
  spec.executables      = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files       = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths    = ['lib']
  spec.has_rdoc         = true
  spec.extra_rdoc_files = ['README.md', 'RDOX']

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'fileutils'
end
