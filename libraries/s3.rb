require File.join(File.dirname(__FILE__), 'ec2')

module Opscode
  module Aws
    module S3
      include Opscode::Aws::Ec2

      def region
      	if new_resource.region
      		new_resource.region
      	else
      		super
      	end
      end

      def s3
      	@@s3 ||= Hash.new
        @@s3[new_resource.region] ||= create_aws_interface(::Aws::S3::Client)
      end
    end
  end
end
