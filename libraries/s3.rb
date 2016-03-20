require File.join(File.dirname(__FILE__), 'ec2')

module Opscode
  module Aws
    module S3
      include Opscode::Aws::Ec2

      def region
        if new_resource.region
          new_resource.region
        else
          query_aws_region
        end
      end

      def s3
        begin
          require 'aws-sdk'
        rescue LoadError
          Chef::Log.fatal("Missing gem 'aws-sdk'. Use the default aws recipe to install it first.")
          raise
        end

        Chef::Log.debug('Initializing the AWS Client')
        @s3 ||= {}
        @s3[new_resource.region] ||= create_aws_interface(::Aws::S3::Client)
      end
    end
  end
end
