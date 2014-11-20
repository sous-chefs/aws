include_recipe 'aws'

aws_s3_file "/tmp/an_file" do
  bucket "aws-cookbook"
  remote_path "an_file"
  aws_access_key_id node['aws_test']['key_id']
  aws_secret_access_key node['aws_test']['access_key']
end
