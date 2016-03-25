require File.join(File.dirname(__FILE__), 'ec2')

module Opscode
  module Aws
    module DynamoDB
      include Opscode::Aws::Ec2

      def dynamodb
        require_aws_sdk

        Chef::Log.debug('Initializing the DynamoDB Client')
        @dynamodb ||= create_aws_interface(::Aws::DynamoDB::Client)
      end
    end
  end
end
