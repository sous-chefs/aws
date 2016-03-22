include_recipe 'aws::default'

aws_s3_file '/tmp/a_file' do
  bucket node['aws_test']['bucket']
  remote_path node['aws_test']['s3key']
  aws_access_key node['aws_test']['key_id']
  aws_secret_access_key node['aws_test']['access_key']
end

# do it again. this will produce an INFO log message and skip the actual action
aws_s3_file '/tmp/a_file' do
  bucket node['aws_test']['bucket']
  remote_path node['aws_test']['s3key']
  aws_access_key_id node['aws_test']['key_id']
  aws_secret_access_key node['aws_test']['access_key']
end
