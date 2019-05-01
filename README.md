# ActionviewPrecompiler

Precompiles ActionView templates at app boot.

The main challenge in precompiling these templates is determining the locals they're going to be passed.
Without the initialization, local vars look the same as method calls, so we need to compile separate copies for each different set of local variable passed in.

We determine the locals passed to each template by parsing all templates looking for render calls and extracting the local keys passed to that.

Right now this assumes every template with the same `virtual_path` takes the same locals (there may be smarter options, we just aren't doing them).
A curse/blessing/actually still a curse of this approach is that mis-predicting render calls doesn't cause any issues, it just wastes RAM.

Templates are half-compiled using standard ActionView handlers, so this should work for erb/builder/haml/whatever.
Parsing is done using Ruby 2.6's `RubyVM::AbstractSyntaxTree`.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'actionview_precompiler'
```

And then execute:

    $ bundle install

## Usage

``` ruby
ActionviewPrecompiler.precompile
```

## TODO

* Doesn't understand (common) relative renders: `render "form"`
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
