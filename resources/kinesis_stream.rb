property :stream_name, String, name_property: true
property :starting_shard_count, Integer, required: true
property :region, String, default: lazy { fallback_region }

# authentication
property :aws_access_key, String
property :aws_secret_access_key, String
property :aws_session_token, String
property :aws_assume_role_arn, String
property :aws_role_session_name, String

include AwsCookbook::Ec2 # needed for aws_region helper

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

action_class do
  include AwsCookbook::Ec2

  def kinesis
    require 'aws-sdk'

    Chef::Log.debug('Initializing the Kinesis Client')
    @kinesis ||= create_aws_interface(::Aws::Kinesis::Client, region: new_resource.region)
  end

  # does_stream_exist - logic for checking if the stream exists
  def stream_exists?
    resp = kinesis.describe_stream(stream_name: new_resource.stream_name)
    if !resp.empty?
      true
    else
      false
    end
  rescue ::Aws::Kinesis::Errors::ResourceNotFoundException
    false
  end
end
