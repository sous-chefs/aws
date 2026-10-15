aws_elastic_lb 'testkitchen-elb' do
  aws_access_key node['aws_test']['key_id']
  aws_secret_access_key node['aws_test']['access_key']
  aws_session_token node['aws_test']['session_token']
  action :create
  availability_zones ['us-west-2a']
  listeners [
    {
      instance_port: 80,
      instance_protocol: 'HTTP',
      load_balancer_port: 80,
      protocol: 'HTTP',
    },
  ]
end

aws_elastic_lb 'testkitchen-elb' do
  aws_access_key node['aws_test']['key_id']
  aws_secret_access_key node['aws_test']['access_key']
  aws_session_token node['aws_test']['session_token']
  action :register
end

aws_elastic_lb 'testkitchen-elb' do
  aws_access_key node['aws_test']['key_id']
  aws_secret_access_key node['aws_test']['access_key']
  aws_session_token node['aws_test']['session_token']
  action :deregister
end

aws_elastic_lb 'testkitchen-elb' do
  aws_access_key node['aws_test']['key_id']
  aws_secret_access_key node['aws_test']['access_key']
  aws_session_token node['aws_test']['session_token']
  action :delete
end
