workflow "New workflow" {
  on = "push"
  resolves = ["Run Tests"]
}

action "Run Tests" {
  uses = "docker://ruby"
  runs = ["sh", "-c", "bundle install -j8 && bundle exec rake test"]
}
