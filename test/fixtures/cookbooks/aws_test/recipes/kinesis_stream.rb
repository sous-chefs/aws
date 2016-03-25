aws_kinesis_stream 'kitchen-test-stream' do
  action :create
  starting_shard_count 2
  aws_access_key node['aws_test']['key_id']
  aws_secret_access_key node['aws_test']['access_key']
end
