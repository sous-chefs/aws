require File.join(File.dirname(__FILE__), 'ec2')

module Opscode
  module Aws
    module Kinesis
      include Opscode::Aws::Ec2

      def kinesis
        begin
          require 'aws-sdk'
        rescue LoadError
          Chef::Log.fatal("Missing gem 'aws-sdk'. Use the default aws recipe to install it first.")
          raise
        end

        Chef::Log.debug('Initializing the AWS Client')
        @kinesis ||= create_aws_interface(::Aws::Kinesis::Client)
      end
    end
  end
end
