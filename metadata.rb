name 'aws'
maintainer 'Chef Software, Inc.'
maintainer_email 'cookbooks@chef.io'
license 'Apache 2.0'
description 'Custom resources for managing AWS resources'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version '3.3.3'

recipe 'aws', 'Installs the aws-sdk gem during compile time'
recipe 'ec2_hints', 'Adds an EC2 hint file for Ohai cloud detection'

source_url 'https://github.com/chef-cookbooks/aws' if respond_to?(:source_url)
issues_url 'https://github.com/chef-cookbooks/aws/issues' if respond_to?(:issues_url)
depends 'ohai', '>= 2.1.0'

%w(ubuntu debian centos redhat amazon scientific fedora oracle freebsd windows).each do |os|
  supports os
end
