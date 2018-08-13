property :return_info, [String, Array]
property :should_decrement_desired_capacity, [true, false], default: true
property :asg_name, String
property :status_code, String
property :max_size, Integer, default: 4

# authentication
property :aws_access_key, String
property :aws_secret_access_key, String
property :aws_session_token, String
property :aws_assume_role_arn, String
property :aws_role_session_name, String
property :region, String, default: lazy { fallback_region }

include AwsCookbook::Ec2 # needed for fallback_region helper

# allow use of the property names from the autoscaling cookbook
alias_method :aws_access_key_id, :aws_access_key
alias_method :aws_region, :region

action :enter_standby do
  unless lifecyclestate == 'Standby'
    converge_by('Entering Standby') do
      request = {
        auto_scaling_group_name: read_asg_name,
        instance_ids: [node['ec2']['instance_id']],
        should_decrement_desired_capacity: should_decrement_desired_capacity,
      }
      resp = autoscaling_client.enter_standby(request)
      node.run_state[new_resource.status_code] = resp.activities[0].status_code
      wait_for_lifecyclestate_change('Standby')
      Chef::Log.debug "Enter Standby for #{node['ec2']['instance_id']}"
    end
  end
end

action :exit_standby do
  unless lifecyclestate == 'InService'
    converge_by('Exiting Standby') do
      request = {
        auto_scaling_group_name: read_asg_name,
        instance_ids: [node['ec2']['instance_id']],
      }
      resp = autoscaling_client.exit_standby(request)
      node.run_state[new_resource.status_code] = resp.activities[0].status_code
      wait_for_lifecyclestate_change('InService')
      Chef::Log.debug "Exit Standby for #{node['ec2']['instance_id']}"
    end
  end
end

action :attach_instance do
  unless lifecyclestate == 'InService'
    converge_by('Attaching Instance') do
      request = {
        auto_scaling_group_name: asg_name,
        instance_ids: [node['ec2']['instance_id']],
      }
      autoscaling_client.attach_instances(request)
      wait_for_lifecyclestate_change('InService')
      Chef::Log.debug "Attach Instance #{node['ec2']['instance_id']} to #{asg_name}"
    end
  end
end

action :detach_instance do
  if lifecyclestate == 'InService'
    converge_by('Detaching Instance') do
      request = {
        auto_scaling_group_name: read_asg_name,
        instance_ids: [node['ec2']['instance_id']],
        should_decrement_desired_capacity: should_decrement_desired_capacity,
      }
      autoscaling_client.detach_instances(request)
      Chef::Log.debug "Detach Instance #{node['ec2']['instance_id']} from #{asg_name}"
    end
  end
end

# Create_asg and create_launch_config are included for testing
# I'm not sure that they would be used in an actual cookbook
action :create_asg do
  request = {
    auto_scaling_group_name: 'AWS_ASG_Test',
    launch_configuration_name: 'AWS_ASG_LC',
    availability_zones: [node['ec2']['availability_zone']],
    max_size: 4,
    min_size: 0,
    desired_capacity: 0,
    vpc_zone_identifier: node['ec2']['subnet_id'],
  }
  autoscaling_client.create_auto_scaling_group(request)
  Chef::Log.debug 'Create ASG'
end

action :delete_asg do
  sleep(10) # give instance time to detach
  request = {
    auto_scaling_group_name: 'AWS_ASG_Test',
    force_delete: true,
  }
  autoscaling_client.delete_auto_scaling_group(request)
  Chef::Log.debug 'Delete ASG'
end

action :create_launch_config do
  request = {
    launch_configuration_name: 'AWS_ASG_LC',
    instance_id: node['ec2']['instance_id'],
    associate_public_ip_address: false,
  }
  autoscaling_client.create_launch_configuration(request)
  Chef::Log.debug 'Create Launch Config'
end

action :delete_launch_config do
  request = {
    launch_configuration_name: 'AWS_ASG_LC',
  }
  autoscaling_client.delete_launch_configuration(request)
  Chef::Log.debug 'Delete Launch Config'
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

  def lcstate
    @lcstate ||= new_resource.status_code
  end

  def read_asg_name
    request = {
      instance_ids: [node['ec2']['instance_id']],
    }
    response = autoscaling_client.describe_auto_scaling_instances(request)
    asg_name = response.auto_scaling_instances[0].auto_scaling_group_name
    Chef::Log.debug "Get ASG Name for #{node['ec2']['instance_id']}, ASG Name = #{asg_name}"
    response.auto_scaling_instances[0].auto_scaling_group_name
  end

  def lifecyclestate
    request = {
      instance_ids: [node['ec2']['instance_id']],
    }
    lcstate = nil
    response = autoscaling_client.describe_auto_scaling_instances(request)
    lcstate = response.auto_scaling_instances[0].lifecycle_state unless response.auto_scaling_instances[0].nil?
    Chef::Log.debug "Get Life Cycle State for #{node['ec2']['instance_id']}, State = #{lcstate}"
    lcstate
  end

  def wait_for_lifecyclestate_change(state)
    lcstate = nil
    while lcstate != state
      sleep(1)
      lcstate = lifecyclestate
      Chef::Log.debug "Wait for Life Cycle State Change for #{node['ec2']['instance_id']}, Status = #{lcstate}, State = #{state}"
    end
  end

  def autoscaling_client
    @autoscaling ||= begin
      require 'aws-sdk-autoscaling'
      Chef::Log.debug('Initializing Aws::AutoScaling::Client')
      create_aws_interface(::Aws::AutoScaling::Client, region: new_resource.region)
    end
  end
end
