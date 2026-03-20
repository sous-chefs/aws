# frozen_string_literal: true

provides :aws_instance_monitoring
unified_mode true

use '_partial/_aws_common'

include AwsCookbook::Ec2 # needed for aws_region helper

action :enable do
  unless monitoring_enabled?
    converge_by('enable monitoring for this instance') do
      ec2.monitor_instances(instance_ids: [node['ec2']['instance_id']])
    end
  end
end

action :disable do
  if monitoring_enabled?
    converge_by('disable monitoring for this instance') do
      ec2.unmonitor_instances(instance_ids: [node['ec2']['instance_id']])
    end
  end
end

action_class do
  include AwsCookbook::Ec2

  def monitoring_enabled?
    monitoring_state = ec2.describe_instances(instance_ids: [node['ec2']['instance_id']])['reservations'][0]['instances'][0]['monitoring']['state']
    Chef::Log.info("Current monitoring state for this instance is #{monitoring_state}")
    monitoring_state == 'enabled' || monitoring_state == 'pending'
  end
end
