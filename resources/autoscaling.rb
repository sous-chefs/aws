property :return_info,				   [String, Array]
property :should_decrement_desired_capacity,	[true, false], default: true
property :asg_name,					   String
property :status_code,				   String
property :max_size,						Integer, default: 2

# authentication
property :aws_access_key,        String
property :aws_secret_access_key, String
property :aws_session_token,     String
property :aws_assume_role_arn,   String
property :aws_role_session_name, String
property :region,                String, default: lazy { fallback_region }

include AwsCookbook::Ec2 # needed for aws_region helper

# allow use of the property names from the autoscaling cookbook
alias_method :aws_access_key_id, :aws_access_key
alias_method :aws_region, :region

action :enter_standby do
  request = {
    auto_scaling_group_name: get_asg_name,
    instance_ids: [node['ec2']['instance_id']],
	should_decrement_desired_capacity: should_decrement_desired_capacity,
  }
  resp = autoscaling_client.enter_standby(request)
  node.run_state[new_resource.status_code] = resp.activities[0].status_code
  get_lifecyclestate("Standby")
  Chef::Log.debug "Enter Standby for #{node['ec2']['instance_id']}"
end

action :exit_standby do
  request = {
    auto_scaling_group_name: get_asg_name,
    instance_ids: [node['ec2']['instance_id']],
  }
  resp = autoscaling_client.exit_standby(request)
  node.run_state[new_resource.status_code] = resp.activities[0].status_code
  get_lifecyclestate("InService")
  Chef::Log.debug "Exit Standby for #{node['ec2']['instance_id']}"
end

action :attach_instance do
  request = {
    auto_scaling_group_name: asg_name,
    instance_ids: [node['ec2']['instance_id']],
  }
  resp = autoscaling_client.attach_instances(request)
  get_lifecyclestate("InService")
  Chef::Log.debug "Attach Instance #{node['ec2']['instance_id']} to #{asg_name}"
end

action :detach_instance do
  request = {
    auto_scaling_group_name: get_asg_name,
    instance_ids: [node['ec2']['instance_id']],
    should_decrement_desired_capacity: should_decrement_desired_capacity,
  }
  resp = autoscaling_client.detach_instances(request)
  Chef::Log.debug "Detach Instance #{node['ec2']['instance_id']} from #{asg_name}"
end

action :create_asg do
  request = {
    auto_scaling_group_name: asg_name,
	max_size: max_size }
end

action_class do
  include AwsCookbook::Ec2

  def name
    @name ||= new_resource.name
  end

  def return_info
    @return_info ||= new_resource.return_info
  end

  def should_decrement_desired_capacity
    @should_decrement_desired_capacity ||= new_resource.should_decrement_desired_capacity
  end

  def asg_name
    @asg_name ||= new_resource.asg_name
  end

  def status_code
    @status_code ||= new_resource.status_code
  end
 
  def max_size
    @max_size ||= new_resource.status_code
  end
 
  def lifecyclestate
    @lifecyclestate ||= new_resource.status_code
  end

  def get_asg_name
    request = {
      instance_ids: [node['ec2']['instance_id']],
    }
    response = autoscaling_client.describe_auto_scaling_instances(request)
	asg_name = response.auto_scaling_instances[0].auto_scaling_group_name
    Chef::Log.debug "Get ASG Name for #{node['ec2']['instance_id']}, ASG Name = #{asg_name}"
    return response.auto_scaling_instances[0].auto_scaling_group_name
  end
  
  def get_lifecyclestate(state)
    request = {
      instance_ids: [node['ec2']['instance_id']],
    }
	lifecyclestate = nil
	while lifecyclestate != state do
	  sleep(1)
      response = autoscaling_client.describe_auto_scaling_instances(request)
      lifecyclestate = response.auto_scaling_instances[0].lifecycle_state
      Chef::Log.debug "Get Life Cycle State for #{node['ec2']['instance_id']}, Status = #{lifecyclestate}, State = #{state}"
	end
  end
  
  def autoscaling_client
    @autoscaling ||= begin
      require 'aws-sdk'
      Chef::Log.debug('Initializing Aws::AutoScaling::Client')
      create_aws_interface(::Aws::AutoScaling::Client, region: new_resource.region)
    end
  end
end
