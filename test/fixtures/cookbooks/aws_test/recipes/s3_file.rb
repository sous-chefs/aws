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

# download a file from s3 in us-west-1 to make sure we can specify region
aws_s3_file '/tmp/a_file_2' do
  bucket node['aws_test']['bucket_west']
  remote_path node['aws_test']['s3key']
  aws_access_key_id node['aws_test']['key_id']
  aws_secret_access_key node['aws_test']['access_key']
  region 'us-west-2'
end
