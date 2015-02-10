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

aws_instance_monitoring 'enable detailed monitoring' do
  aws_access_key node['aws_test']['key_id']
  aws_secret_access_key node['aws_test']['access_key']
end
