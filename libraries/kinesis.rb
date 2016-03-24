require File.join(File.dirname(__FILE__), 'ec2')

module Opscode
  module Aws
    module Kinesis
      include Opscode::Aws::Ec2

      def kinesis
        begin
          require 'aws-sdk'
        rescue LoadError
          chef_gem 'aws-sdk' do
            version node['aws']['aws_sdk_version']
            compile_time true
            action :install
          end

          require 'aws-sdk'
        end

        Chef::Log.debug('Initializing the AWS Client')
        @kinesis ||= create_aws_interface(::Aws::Kinesis::Client)
      end
    end
  end
end
