require File.join(File.dirname(__FILE__), 'ec2')

module AwsCookbook
  module CloudFormation
    include AwsCookbook::Ec2

    def cfn
      require 'aws-sdk'

      Chef::Log.debug('Initializing the CloudFormation Client')
      @cfn ||= create_aws_interface(::Aws::CloudFormation::Client)
    end
  end
end
