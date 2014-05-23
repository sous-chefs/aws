use_inline_resources if defined?(use_inline_resources)

def whyrun_supported?
	true
end
action :put do
	put_s3_file()
end
def put_s3_file()
	s3 = RightAws::S3Interface.new(new_resource.aws_access_key, new_resource.aws_secret_key)
	Chef::Log.info("Attempting to upload: #{new_resource.source} to #{new_resource.bucket}#{new_resource.path}")
	if s3.put(new_resource.bucket, new_resource.path, IO.read(new_resource.source))
		Chef::Log.info("File: #{new_resource.source} saved to #{new_resource.bucket}#{new_resource.path}")
	else
		Chef::Log.error("Failed to upload #{new_resource.source} to #{new_resource.bucket}#{new_resource.path}")
	end
end
