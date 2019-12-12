# Bulk Bundler

**THIS IS A TOTAL HACK JOB. YOU'VE BEEN WARNED.**

This is a standalone command that allows you to install dependencies for multiple Gemfile.lock files in one go.

My sins include:

- parsing `Gemfile.lock` using lots of Regex
- running the `Gemfile` through a bespoke loader I made without almost no knowledge of how Gemfiles are supposed to be loaded
- shelling out to the `gem` command with all variety of command line arguments I may or may not have read about in the man page
- reaching in and cloning repos inside Bundler's special gem directory
- assuming you are using [rbenv](https://github.com/rbenv/rbenv)

And I'm sure there more!

## Installation

**I'm not pushing this to Rubygems for I fear its bad behavior might spread to other upstanding gem citizens.**

If you are brave enough to try it (you aren't), you can build the gem and install it locally.

```sh
gem build bulk_bundler.gemspec
gem install bulk_bundler-*.gem
```

## Usage

```sh
bulk_bundle proj1/Gemfile.lock proj2/Gemfile.lock ...
```

## Contributing

Please don't.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT). Look and laugh.
