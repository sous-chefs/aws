aws_secondary_ip 'add secondary IP' do
  ip '172.31.37.18'
  aws_access_key node['aws_test']['key_id']
  aws_secret_access_key node['aws_test']['access_key']
  aws_session_token node['aws_test']['session_token']
end

aws_secondary_ip 'remove secondary IP' do
  ip '172.31.37.18'
  action :unassign
  aws_access_key node['aws_test']['key_id']
  aws_secret_access_key node['aws_test']['access_key']
  aws_session_token node['aws_test']['session_token']
end
