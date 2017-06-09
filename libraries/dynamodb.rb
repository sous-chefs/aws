require File.join(File.dirname(__FILE__), 'ec2')

module AwsCookbook
  module DynamoDB
    include AwsCookbook::Ec2

    def dynamodb
      require 'aws-sdk'

      Chef::Log.debug('Initializing the DynamoDB Client')
      @dynamodb ||= create_aws_interface(::Aws::DynamoDB::Client, region: new_resource.region)
    end
  end
end
