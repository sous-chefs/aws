require File.join(File.dirname(__FILE__), 'ec2')

module Opscode
  module Aws
    module IAM
      include Opscode::Aws::Ec2

      def iam
        begin
          require 'aws-sdk'
        rescue LoadError
          Chef::Log.fatal("Missing gem 'aws-sdk'. Use the default aws recipe to install it first.")
          raise
        end

        Chef::Log.debug('Initializing the AWS Client')
        @iam ||= create_aws_interface(::Aws::IAM::Client)
      end
    end
  end
end
