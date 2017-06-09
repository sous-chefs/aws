require File.join(File.dirname(__FILE__), 'ec2')

module AwsCookbook
  module IAM
    include AwsCookbook::Ec2

    def iam
      require 'aws-sdk'

      Chef::Log.debug('Initializing the IAM Client')
      @iam ||= create_aws_interface(::Aws::IAM::Client, region: new_resource.region)
    end
  end
end
