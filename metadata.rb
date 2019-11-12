name 'aws'
maintainer 'Chef Software, Inc.'
maintainer_email 'cookbooks@chef.io'
license 'Apache-2.0'
description 'Provides resources for managing AWS resources'
version '8.1.1'

%w(ubuntu debian centos redhat amazon scientific fedora oracle freebsd windows suse opensuse opensuseleap).each do |os|
  supports os
end

source_url 'https://github.com/chef-cookbooks/aws'
issues_url 'https://github.com/chef-cookbooks/aws/issues'
chef_version '>= 12.9'

# Pin the aws sdk to the minor version to only pull
# in new patches by default. For some of these
# gems AWS typically releases a new minor version
# daily so this should reduce the number of gem
# versions that someone has installed.
gem 'aws-sdk-cloudformation', '~> 1.21.0'
gem 'aws-sdk-cloudwatch', '~> 1.22.0'
gem 'aws-sdk-core', '~> 3.71.0'
gem 'aws-sdk-dynamodb', '~> 1.28.0'
gem 'aws-sdk-ec2', '~> 1.115.0'
gem 'aws-sdk-elasticloadbalancing', '~> 1.14.0'
gem 'aws-eventstream', '~> 1.0.3'
gem 'aws-sdk-iam', '~> 1.22.0'
gem 'aws-sdk-kinesis', '~> 1.15.0'
gem 'aws-sdk-kms', '~> 1.20.0'
gem 'aws-sdk-route53', '~> 1.24.0'
gem 'aws-partitions', '~> 1.228.0'
gem 'aws-sdk-s3', '~> 1.38.0'
gem 'aws-sigv4', '~> 1.1.0'
gem 'aws-sdk-ssm', '~> 1.46.0'
