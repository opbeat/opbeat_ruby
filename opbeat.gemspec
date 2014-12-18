# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'opbeat/version'

Gem::Specification.new do |gem|
  gem.name             = "opbeat"
  gem.version          = Opbeat::VERSION
  gem.authors          = ["Thomas Watson Steen", "Ron Cohen", "Noah Kantrowitz"]
  gem.email            = "support@opbeat.com"
  gem.summary          = "The official Opbeat Ruby client"
  gem.homepage         = "https://github.com/opbeat/opbeat_ruby"
  gem.license          = "Apache-2.0"

  gem.files            = `git ls-files -z`.split("\x0")
  gem.require_paths    = ["lib"]
  gem.extra_rdoc_files = ["README.md", "LICENSE"]

  gem.add_dependency "faraday", [">= 0.7.6", "< 0.10"]
  gem.add_dependency "multi_json", "~> 1.0"

  gem.add_development_dependency "bundler", "~> 1.7"
  gem.add_development_dependency "rake", "~> 10.0"
  gem.add_development_dependency "rspec", ">= 2.14"
  gem.add_development_dependency "simplecov"
  gem.add_development_dependency "delayed_job"
  gem.add_development_dependency "sidekiq", "~> 2.17.0"
end
