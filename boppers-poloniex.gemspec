# frozen_string_literal: true

require "./lib/boppers/poloniex/version"

Gem::Specification.new do |spec|
  spec.name          = "boppers-poloniex"
  spec.version       = Boppers::Poloniex::VERSION
  spec.authors       = ["Author"]
  spec.email         = ["author@example.com"]

  spec.summary       = "Some description"
  spec.description   = spec.summary
  spec.homepage      = "https://rubygems.org/gems/boppers-poloniex"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) {|f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "boppers"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "minitest-utils"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "pry-meta"
  spec.add_development_dependency "webmock"
  spec.add_development_dependency "mocha"
end
