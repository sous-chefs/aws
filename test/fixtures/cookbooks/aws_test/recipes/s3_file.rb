aws_s3_bucket 'create test bucket' do
  name 'this-better-be-unique-chef-aws'
  aws_access_key node['aws_test']['key_id']
  aws_secret_access_key node['aws_test']['access_key']
  aws_session_token node['aws_test']['session_token']
  region 'us-west-2'
end

aws_s3_bucket 'turn on versioning' do
  name 'this-better-be-unique-chef-aws'
  aws_access_key node['aws_test']['key_id']
  aws_secret_access_key node['aws_test']['access_key']
  aws_session_token node['aws_test']['session_token']
  versioning true
end

aws_s3_bucket 'delete test bucket' do
  name 'this-better-be-unique-chef-aws'
  aws_access_key node['aws_test']['key_id']
  aws_secret_access_key node['aws_test']['access_key']
  aws_session_token node['aws_test']['session_token']
  region 'us-west-2'
  delete_all_objects true # delete the bucket if it's not empty
  action :delete
end

aws_s3_file '/tmp/a_file' do
  bucket node['aws_test']['bucket']
  remote_path node['aws_test']['s3key']
  aws_access_key node['aws_test']['key_id']
  aws_secret_access_key node['aws_test']['access_key']
  aws_session_token node['aws_test']['session_token']
end

# do it again. this will produce an INFO log message and skip the actual action
aws_s3_file '/tmp/a_file' do
  bucket node['aws_test']['bucket']
  remote_path node['aws_test']['s3key']
  aws_access_key_id node['aws_test']['key_id'] # use the legacy property name
  aws_secret_access_key node['aws_test']['access_key']
  aws_session_token node['aws_test']['session_token']
end

# download a file from s3 in us-west-1 to make sure we can specify region
aws_s3_file '/tmp/a_file_2' do
  bucket node['aws_test']['bucket_west']
  remote_path node['aws_test']['s3key']
  aws_access_key node['aws_test']['key_id'] # use the modern property name
  aws_secret_access_key node['aws_test']['access_key']
  aws_session_token node['aws_test']['session_token']
  region 'us-west-2'
end
