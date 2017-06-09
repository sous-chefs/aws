property :aws_access_key, String
property :aws_secret_access_key, String
property :aws_session_token, String
property :aws_assume_role_arn, String
property :aws_role_session_name, String
property :region, String, default: lazy { fallback_region }

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
