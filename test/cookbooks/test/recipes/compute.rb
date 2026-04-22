# frozen_string_literal: true

include_recipe 'aws_test::instance_monitoring'
include_recipe 'aws_test::instance_term_protection'
include_recipe 'aws_test::autoscaling'

file '/tmp/aws-live-compute-suite' do
  content 'compute suite converged'
  mode '0644'
end
