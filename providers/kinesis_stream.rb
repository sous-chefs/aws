include Opscode::Aws::Kinesis

use_inline_resources

def whyrun_supported?
  true
end

# does_stream_exist - logic for checking if the stream exists
def stream_exists?
  resp = kinesis.describe_stream(stream_name: new_resource.stream_name)
  if resp.length > 0
    true
  else
    false
  end
rescue ::Aws::Kinesis::Errors::ResourceNotFoundException
  false
end

action :create do
  unless stream_exists?
    converge_by("create Kinesis stream #{new_resource.stream_name}") do
      kinesis.create_stream(
        stream_name: new_resource.stream_name,
        shard_count: new_resource.starting_shard_count
      )
    end
  end
end

action :delete do
  if stream_exists?
    converge_by("delete Kinesis stream #{new_resource.stream_name}") do
      kinesis.delete_stream(stream_name: new_resource.stream_name)
    end
  end
end
