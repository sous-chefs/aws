require File.join(File.dirname(__FILE__), 'ec2')

module Opscode
  module Aws
    module Kinesis
      include Opscode::Aws::Ec2

      def kinesis
        @kinesis ||= create_aws_interface(::Aws::Kinesis::Client)
      end
    end
  end
end
