require File.join(File.dirname(__FILE__), 'ec2')

module Opscode
  module Aws
    module Kinesis
      include Opscode::Aws::Ec2

      def kinesis
        require_aws_sdk

        Chef::Log.debug('Initializing the Kinesis Client')
        @kinesis ||= create_aws_interface(::Aws::Kinesis::Client)
      end
    end
  end
end
