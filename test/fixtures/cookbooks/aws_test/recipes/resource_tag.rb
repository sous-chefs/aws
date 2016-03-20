aws_resource_tag node['ec2']['instance_id'] do
  aws_access_key node['aws_test']['key_id']
  aws_secret_access_key node['aws_test']['access_key']
  tags('Name' => 'AWS Cookbook Test Node',
       'Environment' => node.chef_environment)
  action :update
end
