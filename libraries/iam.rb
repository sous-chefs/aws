require File.join(File.dirname(__FILE__), 'ec2')

module Opscode
  module Aws
    module IAM
      include Opscode::Aws::Ec2

      def iam
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
        @iam ||= create_aws_interface(::Aws::IAM::Client)
      end
    end
  end
end
