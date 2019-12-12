lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "bulk_bundler/version"

Gem::Specification.new do |spec|
  spec.name          = "bulk_bundler"
  spec.version       = BulkBundler::VERSION
  spec.authors       = ["Tim Morgan"]
  spec.email         = ["tim@timmorgan.org"]

  spec.summary       = %q{Install gems for multiple projects with one command}
  spec.description   = %q{A command that installs gems for multiple Gemfile.lock files in one go}
  spec.homepage      = "https://github.com/seven1m/bulk-bundler"
  spec.license       = "MIT"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "rake", "~> 10.0"
end
