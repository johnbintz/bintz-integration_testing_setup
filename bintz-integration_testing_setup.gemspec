# -*- encoding: utf-8 -*-
Gem::Specification.new do |gem|
  gem.authors       = ["John Bintz"]
  gem.email         = ["john@coswellproductions.com"]
  gem.description   = %q{The way that I set up my projects for fast, continuous integration testing using Cucumber and Capybara}
  gem.summary       = %q{The way that I set up my projects for fast, continuous integration testing using Cucumber and Capybara}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "bintz-integration_testing_setup"
  gem.require_paths = ["lib"]
  gem.version       = "0.0.1"

  gem.add_dependency 'thor'
end

