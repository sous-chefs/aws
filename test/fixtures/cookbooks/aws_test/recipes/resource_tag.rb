include_recipe 'aws'

directory '/etc/chef/ohai/hints' do
  recursive true
  action :create
end.run_action(:create)

file '/etc/chef/ohai/hints/ec2.json' do
  content {}
  action :create
end.run_action(:create)

ohai 'reload' do
  action :reload
end.run_action(:reload)

aws_resource_tag node['ec2']['instance_id'] do
  aws_access_key node['aws_test']['key_id']
  aws_secret_access_key node['aws_test']['access_key']
  tags('Name' => 'AWS Cookbook Test Node',
       'Environment' => node.chef_environment)
  action :update
end
