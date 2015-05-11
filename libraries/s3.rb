require File.join(File.dirname(__FILE__), 'ec2')

module Opscode
  module Aws
    module S3
      include Opscode::Aws::Ec2

      def s3(bucket_region=nil)
        if bucket_region
            @@instance_region = bucket_region
        end
        @@s3 ||= create_aws_interface(::Aws::S3::Client)
      end
    end
  end
end
