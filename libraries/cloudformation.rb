require File.join(File.dirname(__FILE__), 'ec2')

module Opscode
  module Aws
    module CloudFormation
      include Opscode::Aws::Ec2

      def cfn
        begin
          require 'aws-sdk'
        rescue LoadError
          Chef::Log.fatal("Missing gem 'aws-sdk'. Use the default aws recipe to install it first.")
          raise
        end

        Chef::Log.debug('Initializing the AWS Client')
        @cfn ||= create_aws_interface(::Aws::CloudFormation::Client)
      end
    end
  end
end
