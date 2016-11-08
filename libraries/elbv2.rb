require File.join(File.dirname(__FILE__), 'ec2')

module Opscode
  module Aws
    module ElbV2
      include Opscode::Aws::Ec2

      def elbv2
        require_aws_sdk

        Chef::Log.debug('Initializing the ElasticLoadBalancingV2 Client')
        @elbv2 ||= create_aws_interface(::Aws::ElasticLoadBalancingV2::Client)
      end
    end
  end
end
