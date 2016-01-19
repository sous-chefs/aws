require File.join(File.dirname(__FILE__), 'ec2')

module Opscode
  module Aws
    module Elb
      include Opscode::Aws::Ec2

      def elb
        begin
          require 'aws-sdk'
        rescue LoadError
          Chef::Log.error("Missing gem 'aws-sdk'. Use the default aws recipe to install it first.")
        end
        @@elb ||= create_aws_interface(::Aws::ElasticLoadBalancing::Client)
      end
    end
  end
end
