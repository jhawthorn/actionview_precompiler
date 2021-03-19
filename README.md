# ActionviewPrecompiler

Provides eager loading of Action View templates.

This optimization aims to improve cold render times and to allow more memory to be shared via CoW on forking web servers.

For more information see:

* https://www.johnhawthorn.com/2019/09/precompiling-rails-templates/
* Aaron Patterson's [RailsConf 2019 Keynote](https://www.youtube.com/watch?v=8Dld5kFWGCc)
* John Hawthorn's ["Parsing and Rewriting Ruby Templates" (slides)](https://www.slideshare.net/JohnHawthorn4/parsing-and-rewriting-ruby-templates)

## Should I use this?

You probably don't need to.

This gem provides a place to test out an optimization we hope to eventually include in Rails where everyone can gain this benefit without any additional work or configuration :hugs:.
Right now I would love help validating that it (at least somewhat) accurately detects rendered views in your application :heart:.

That said, it shows [promising results](https://www.johnhawthorn.com/2019/09/precompiling-rails-templates/) today :chart_with_downwards_trend: so if you've measured that view compilation is an issue this should help! Please let me know!

The most likely downside of using this is that if this mispredicts render calls it will waste a little memory (somewhat ironically, since one goal is to save memory).

## How it works

The main challenge in precompiling these templates is determining the locals they're going to be passed.
Without the initialization, local vars look the same as method calls, so we need to compile separate copies for each different set of local variable passed in.

We determine the locals passed to each template by parsing all templates looking for render calls and extracting the local keys passed to that.

Right now this assumes every template with the same `virtual_path` takes the same locals (there may be smarter options, we just aren't doing them).
A curse/blessing/actually still a curse of this approach is that mis-predicting render calls doesn't cause any issues, it just wastes RAM.

Templates are half-compiled using standard Action View handlers, so this should work for erb/builder/haml/whatever.
Parsing is done using either Ruby 2.6's `RubyVM::AbstractSyntaxTree` or JRuby's parser.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'actionview_precompiler'
```

And then execute:

    $ bundle install

## Usage

To precompile views on app boot, create an initializer to perform precompilation

``` ruby
# config/initializers/actionview_precompiler.rb
ActionviewPrecompiler.precompile
```

It can also be run in verbose mode, which I use to tell which views it has detected. I usually run this in a console

``` ruby
ActionviewPrecompiler.precompile(verbose: true)
```

## TODO

* Support more `render` invocations
* Parse controllers/helpers for more renders
* Cache detected locals to avoid parsing cost
* Upstream more bits to Rails

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/jhawthorn/actionview_precompiler. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## Code of Conduct

Everyone interacting in the ActionviewPrecompiler project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/jhawthorn/actionview_precompiler/blob/master/CODE_OF_CONDUCT.md).
