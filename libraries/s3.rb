require File.join(File.dirname(__FILE__), 'ec2')

module Opscode
  module Aws
    module S3
      include Opscode::Aws::Ec2

      def s3
        require_aws_sdk

        Chef::Log.debug('Initializing the S3 Client')
        @s3 ||= create_aws_interface(::Aws::S3::Client)
      end

      def s3_obj
        require_aws_sdk
        remote_path = new_resource.remote_path
        remote_path.sub!(%r{^/*}, '')

        Chef::Log.debug("Initializing the S3 Object for bucket: #{new_resource.bucket} path: #{remote_path}")
        @s3_obj ||= ::Aws::S3::Object.new(bucket_name: new_resource.bucket, key: remote_path, client: s3)
      end

      def compare_md5s(remote_object, local_file_path)
        return false unless ::File.exist?(local_file_path)
        local_md5 = ::Digest::MD5.new
        remote_hash = remote_object.etag.delete('"') # etags are always quoted

        ::File.open(local_file_path, 'rb') do |f|
          f.each_line do |line|
            local_md5.update line
          end
        end

        local_hash = local_md5.hexdigest

        Chef::Log.debug "Remote file md5 hash:  #{remote_hash}"
        Chef::Log.debug "Local file md5 hash:   #{local_hash}"

        local_hash == remote_hash
      end
    end
  end
end
