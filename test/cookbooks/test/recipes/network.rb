# frozen_string_literal: true

include_recipe 'aws_test::elastic_ip'
include_recipe 'aws_test::elb'
include_recipe 'aws_test::resource_tag'
include_recipe 'aws_test::route53'
include_recipe 'aws_test::secondary_ip'

aws_security_group 'aws-cookbook-test-security-group' do
  description 'Managed by Test Kitchen'
  vpc_id node['aws_test']['vpc_id']
  action :create
  only_if { node['aws_test']['vpc_id'] }
end

file '/tmp/aws-live-network-suite' do
  content 'network suite converged'
  mode '0644'
end
