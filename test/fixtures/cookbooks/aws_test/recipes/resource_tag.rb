aws_resource_tag node['ec2']['instance_id'] do
  aws_access_key node['aws_test']['key_id']
  aws_secret_access_key node['aws_test']['access_key']
  aws_session_token node['aws_test']['session_token']
  tags('Name' => 'AWS Cookbook Test Node',
       'Environment' => 'test_kitchen')
  action :update
end

aws_resource_tag 'Add a single tag' do
  resource_id node['ec2']['instance_id']
  aws_access_key node['aws_test']['key_id']
  aws_secret_access_key node['aws_test']['access_key']
  aws_session_token node['aws_test']['session_token']
  tags('foo' => 'bar')
  action :add
end

aws_resource_tag 'Remove Environment tag' do
  resource_id node['ec2']['instance_id']
  aws_access_key node['aws_test']['key_id']
  aws_secret_access_key node['aws_test']['access_key']
  aws_session_token node['aws_test']['session_token']
  tags('Environment' => 'test_kitchen')
  action :force_remove
end
