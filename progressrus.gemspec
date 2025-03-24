# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'progressrus/version'

Gem::Specification.new do |spec|
  spec.name          = "progressrus"
  spec.version       = Progressrus::VERSION
  spec.authors       = ["Simon Eskildsen"]
  spec.email         = ["sirup@sirupsen.com"]
  spec.description   = %q{Monitor the progress of remote, long-running jobs.}
  spec.summary       = %q{Monitor the progress of remote, long-running jobs.}
  spec.homepage      = "https://github.com/Sirupsen/progressrus"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "redis", ">= 4.7.0"
  spec.add_dependency "ruby-progressbar", "~> 1.0"

  spec.add_development_dependency "rake"
  spec.add_development_dependency "mocha", "~> 2.7"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "byebug"
  spec.add_development_dependency "pry-byebug"
  spec.add_development_dependency "minitest"
end
