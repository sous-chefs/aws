require File.join(File.dirname(__FILE__), 'ec2')

module Opscode
  module Aws
    module IAM
      include Opscode::Aws::Ec2

      def iam
        require_aws_sdk

        Chef::Log.debug('Initializing the IAM Client')
        @iam ||= create_aws_interface(::Aws::IAM::Client)
      end
    end
  end
end
