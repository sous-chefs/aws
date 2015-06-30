include_recipe 'aws'

aws_elastic_ip 'elastic_ip' do
  aws_access_key node['aws_test']['key_id']
  aws_secret_access_key node['aws_test']['access_key']
  ip node['aws_test']['elastic_ip']
  action :associate
end
