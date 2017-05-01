require File.join(File.dirname(__FILE__), 'ec2')

module Opscode
  module Aws
    module CloudWatch
      include Opscode::Aws::Ec2

      def cwh
        require 'aws-sdk'
        Chef::Log.debug('Initializing the CloudWatch Client')
        @cwh ||= create_aws_interface(::Aws::CloudWatch::Client)
      end
    end
  end
end
