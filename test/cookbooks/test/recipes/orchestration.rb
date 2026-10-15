# frozen_string_literal: true

include_recipe 'aws_test::cfn_stack'
include_recipe 'aws_test::cloudwatch_alarm'
include_recipe 'aws_test::kinesis_stream'

file '/tmp/aws-live-orchestration-suite' do
  content 'orchestration suite converged'
  mode '0644'
end
