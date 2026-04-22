# frozen_string_literal: true

include_recipe 'aws_test::dynamodb_table'
include_recipe 'aws_test::ebs_volume'
include_recipe 'aws_test::s3_file'

file '/tmp/aws-live-storage-suite' do
  content 'storage suite converged'
  mode '0644'
end
