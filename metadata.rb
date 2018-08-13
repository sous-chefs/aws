name 'aws'
maintainer 'Chef Software, Inc.'
maintainer_email 'cookbooks@chef.io'
license 'Apache-2.0'
description 'Provides resources for managing AWS resources'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version '7.5.0'

%w(ubuntu debian centos redhat amazon scientific fedora oracle freebsd windows suse opensuse opensuseleap).each do |os|
  supports os
end

source_url 'https://github.com/chef-cookbooks/aws'
issues_url 'https://github.com/chef-cookbooks/aws/issues'
chef_version '>= 12.9' if respond_to?(:chef_version)

gem 'aws-sdk-cloudformation'
gem 'aws-sdk-cloudwatch'
gem 'aws-sdk-core'
gem 'aws-sdk-dynamodb'
gem 'aws-sdk-ec2'
gem 'aws-sdk-elasticloadbalancing'
gem 'aws-sdk-iam'
gem 'aws-sdk-kinesis'
gem 'aws-sdk-route53'
gem 'aws-sdk-s3'
gem 'aws-sdk-ssm'
