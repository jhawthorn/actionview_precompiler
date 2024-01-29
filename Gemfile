source "https://rubygems.org"

gem "pry", ">= 0.14.1"

# Specify your gem's dependencies in actionview_precompiler.gemspec
gemspec

if rails_version = ENV.fetch("RAILS_VERSION", "main")
  if rails_version =~ /\A[0-9]+\./
    gem "rails", rails_version
  else
    gem "rails", github: "rails/rails", branch: rails_version
  end
end

# Required only if you want to use the Syntax Tree backend.
gem "syntax_tree", platforms: :ruby

gem "prism"
