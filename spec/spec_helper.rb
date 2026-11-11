# frozen_string_literal: true

require 'chefspec'
require 'tmpdir'

RSpec.configure do |config|
  # Both cookbooks are local; specs must not resolve dependencies over the network.
  cookbook_path = Dir.mktmpdir('aws-chefspec-')
  File.symlink(File.expand_path('..', __dir__), File.join(cookbook_path, 'aws'))
  File.symlink(File.expand_path('../test/fixtures/cookbooks/aws_test', __dir__), File.join(cookbook_path, 'aws_test'))
  config.cookbook_path = cookbook_path
  config.after(:suite) { FileUtils.remove_entry(cookbook_path) }
  config.color = true               # Use color in STDOUT
  config.formatter = :documentation # Use the specified formatter
  config.log_level = :error         # Avoid deprecation notice SPAM
end
