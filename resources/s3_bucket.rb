property :region, String, default: lazy { fallback_region }
property :delete_all_objects, [true, false], default: false
property :versioning, [true, false], default: false, desired_state: false

# authentication
property :aws_access_key, String
property :aws_secret_access_key, String
property :aws_session_token, String
property :aws_assume_role_arn, String
property :aws_role_session_name, String

include AwsCookbook::Ec2 # needed for aws_region helper

action :create do
  if s3_bucket.exists?
    unless new_resource.versioning == versioning_enabled?
      desired_state = new_resource.versioning ? 'Enabled' : 'Disabled'
      update_versioning_status(desired_state)
    end
  else # create the bucket from scratch
    converge_by "create S3 bucket #{new_resource.name}" do
      s3_bucket.create
      s3_bucket.wait_until_exists
    end
  end
end

action :delete do
  if s3_bucket.exists?
    begin
      if new_resource.delete_all_objects
        converge_by "delete S3 bucket #{new_resource.name} and all containing objects" do
          s3_bucket.delete!
          s3_bucket.wait_until_not_exists
        end
      else
        converge_by "delete S3 bucket #{new_resource.name}" do
          begin
            s3_bucket.delete
            s3_bucket.wait_until_not_exists
          rescue Aws::S3::Errors::BucketNotEmpty
            raise "S3 bucket #{new_resource.name} is not empty. If you are ABSOLUTELY SURE you want to delete the bucket and everything in it set delete_all_objects to true"
          end
        end
      end
    rescue Aws::S3::Errors::PermanentRedirect
      raise "Permanent redirect received from AWS attempting to delete bucket #{new_resource.name}. This generally means you have the region of the bucket wrong"
    end
  else
    Chef::Log.info("S3 bucket #{new_resource.name} not found so not deleted")
  end
end

action_class do
  include AwsCookbook::Ec2

  def versioning_enabled?
    v_data = s3_client.get_bucket_versioning(bucket: new_resource.name)
    v_data.status == 'Enabled'
  end

  def update_versioning_status(state)
    converge_by("set #{new_resource.name} versioning to #{state}") do
      s3_client.put_bucket_versioning(bucket: new_resource.name,
                                      versioning_configuration: {
                                        status: state,
                                      })
    end
  end

  def s3_client
    @s3_client ||= begin
      require 'aws-sdk'
      Chef::Log.debug('Initializing Aws::S3::Client')
      create_aws_interface(::Aws::S3::Client, region: new_resource.region)
    end
  end

  def s3_bucket
    @s3_bucket ||= begin
      require 'aws-sdk'
      Chef::Log.debug('Initializing Aws::S3::Bucket')
      ::Aws::S3::Bucket.new(new_resource.name, client: s3_client)
    end
  end
end
