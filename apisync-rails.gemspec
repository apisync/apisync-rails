# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "apisync/rails/version"

Gem::Specification.new do |spec|
  spec.name          = "apisync-rails"
  spec.version       = Apisync::Rails::VERSION
  spec.authors       = ["Alexandre de Oliveira"]
  spec.email         = ["chavedomundo@gmail.com"]

  spec.summary       = %q{Official Rails client to apisync.io}
  spec.description   = %q{Use this gem if you're using Rails. If you're not using Rails, then use apisync-ruby gem.}
  spec.homepage      = "https://github.com/apisync/apisync-rails"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activesupport", ">= 4.2"
  spec.add_dependency "activerecord", ">= 4.2"
  spec.add_dependency "apisync", ">= 0.1.4"

  spec.add_development_dependency "bundler", "~> 1.15"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.5"
  spec.add_development_dependency "rails", "~> 5.0"
  spec.add_development_dependency "sqlite3"
  spec.add_development_dependency "awesome_print"
  spec.add_development_dependency "database_cleaner"
  spec.add_development_dependency "webmock"
  spec.add_development_dependency "pry"
end
