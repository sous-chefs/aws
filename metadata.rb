name 'aws'
maintainer 'Chef Software, Inc.'
maintainer_email 'cookbooks@chef.io'
license 'Apache-2.0'
description 'Provides resources for managing AWS resources'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version '7.4.1'

%w(ubuntu debian centos redhat amazon scientific fedora oracle freebsd windows suse opensuse opensuseleap).each do |os|
  supports os
end

source_url 'https://github.com/chef-cookbooks/aws'
issues_url 'https://github.com/chef-cookbooks/aws/issues'
chef_version '>= 12.9' if respond_to?(:chef_version)

gem 'aws-sdk', '>= 2', '< 4.0'
