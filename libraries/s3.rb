require File.join(File.dirname(__FILE__), 'ec2')

module Opscode
  module Aws
    module S3
      include Opscode::Aws::Ec2

      def s3
        begin
          require 'aws-sdk'
        rescue LoadError
          Chef::Log.error("Missing gem 'aws-sdk'. Use the default aws recipe to install it first.")
        end
        @@s3 ||= create_aws_interface(::Aws::S3::Client)
      end

      def compare_md5s(remote_object, local_file_path)
        local_md5 = Digest::MD5.new
        remote_hash = remote_object.etag

        File.open(local_file_path, 'rb') do |f|
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
