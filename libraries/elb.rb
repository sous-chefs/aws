require File.join(File.dirname(__FILE__), 'ec2')

module Opscode
  module Aws
    module Elb
      include Opscode::Aws::Ec2

      def elb
        require_aws_sdk

        Chef::Log.debug('Initializing the ElasticLoadBalancing Client')
        @elb ||= create_aws_interface(::Aws::ElasticLoadBalancing::Client)
      end
    end
  end
end
