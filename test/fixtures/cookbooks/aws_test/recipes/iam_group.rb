aws_iam_group 'test-kitchen-group' do
  aws_access_key node['aws_test']['key_id']
  aws_secret_access_key node['aws_test']['access_key']
  aws_session_token node['aws_test']['session_token']
  action :create
end

aws_iam_group 'test-kitchen-group' do
  aws_access_key node['aws_test']['key_id']
  aws_secret_access_key node['aws_test']['access_key']
  aws_session_token node['aws_test']['session_token']
  action :delete
end
