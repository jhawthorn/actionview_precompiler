lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "actionview_precompiler/version"

Gem::Specification.new do |spec|
  spec.name          = "actionview_precompiler"
  spec.version       = ActionviewPrecompiler::VERSION
  spec.authors       = ["John Hawthorn"]
  spec.email         = ["john@hawthorn.email"]

  spec.summary       = %q{Precompiles ActionView templates}
  spec.description   = %q{Parses templates for render calls and uses them to precompile}
  spec.homepage      = "https://github.com/jhawthorn/actionview_precompiler"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir["lib/**/*.rb"]
  spec.files << "README.md"

  spec.license = "MIT"

  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.6" unless RUBY_ENGINE == 'jruby'

  spec.add_dependency "actionview", ">= 6.0.a"

  spec.add_development_dependency "bundler", "~> 2.1"
  spec.add_development_dependency "rake", "~> 12.0"
  spec.add_development_dependency "minitest", "~> 5.0"
end
