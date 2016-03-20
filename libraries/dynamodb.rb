require File.join(File.dirname(__FILE__), 'ec2')

module Opscode
  module Aws
    module DynamoDB
      include Opscode::Aws::Ec2

      def dynamodb
        begin
          require 'aws-sdk'
        rescue LoadError
          Chef::Log.fatal("Missing gem 'aws-sdk'. Use the default aws recipe to install it first.")
          raise
        end

        Chef::Log.debug('Initializing the AWS Client')
        @dynamodb ||= create_aws_interface(::Aws::DynamoDB::Client)
      end
    end
  end
end
