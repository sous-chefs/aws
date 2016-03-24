require File.join(File.dirname(__FILE__), 'ec2')

module Opscode
  module Aws
    module DynamoDB
      include Opscode::Aws::Ec2

      def dynamodb
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
        @dynamodb ||= create_aws_interface(::Aws::DynamoDB::Client)
      end
    end
  end
end
