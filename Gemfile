source "https://rubygems.org"

gem "pry"

# Specify your gem's dependencies in actionview_precompiler.gemspec
gemspec

if rails_version = ENV.fetch("RAILS_VERSION", "master")
  if rails_version =~ /\A[0-9]+\./
    gem "rails", rails_version
  else
    gem "rails", github: "rails/rails", branch: rails_version
  end
end
