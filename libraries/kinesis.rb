require File.join(File.dirname(__FILE__), 'ec2')

module AwsCookbook
  module Kinesis
    include AwsCookbook::Ec2

    def kinesis
      require 'aws-sdk'

      Chef::Log.debug('Initializing the Kinesis Client')
      @kinesis ||= create_aws_interface(::Aws::Kinesis::Client)
    end
  end
end
