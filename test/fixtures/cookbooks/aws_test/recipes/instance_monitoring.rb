aws_instance_monitoring 'enable detailed monitoring' do
  aws_access_key node['aws_test']['key_id']
  aws_secret_access_key node['aws_test']['access_key']
end
