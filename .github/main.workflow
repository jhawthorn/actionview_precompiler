workflow "New workflow" {
  on = "push"
  resolves = ["Test MRI", "Test jRuby"]
}

action "Test MRI" {
  uses = "docker://ruby"
  runs = ["sh", "-c", "bundle install -j8 && bundle exec rake test"]
}

action "Test jRuby" {
  uses = "docker://jruby"
  runs = ["sh", "-c", "bundle install -j8 && bundle exec rake test"]
}
