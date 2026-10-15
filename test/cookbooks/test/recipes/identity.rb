# frozen_string_literal: true

include_recipe 'aws_test::iam_user'
include_recipe 'aws_test::iam_group'
include_recipe 'aws_test::iam_role'
include_recipe 'aws_test::iam_policy'
include_recipe 'aws_test::ssm_parameter_store'

file '/tmp/aws-live-identity-suite' do
  content 'identity suite converged'
  mode '0644'
end
