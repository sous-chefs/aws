aws_elastic_ip 'elastic_ip' do
  aws_access_key node['aws_test']['key_id']
  aws_secret_access_key node['aws_test']['access_key']
  aws_session_token node['aws_test']['session_token']
  ip node['aws_test']['elastic_ip']
  action :associate
end

aws_elastic_ip 'elastic_ip' do
  aws_access_key node['aws_test']['key_id']
  aws_secret_access_key node['aws_test']['access_key']
  aws_session_token node['aws_test']['session_token']
  ip node['aws_test']['elastic_ip']
  action :disassociate
end
