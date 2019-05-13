workflow "Run tests on push" {
  on = "push"
  resolves = ["Test MRI", "Test JRuby"]
}

action "Test MRI" {
  uses = "docker://ruby"
  runs = ["sh", "-c", "bundle install -j8 && bundle exec rake test"]
}

action "Test JRuby" {
  uses = "docker://jruby"
  runs = ["sh", "-c", "bundle install -j8 && bundle exec rake test"]
}
