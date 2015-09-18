aws_kinesis_stream 'kitchen-test-stream' do
  action :create
  starting_shard_count 2
end
