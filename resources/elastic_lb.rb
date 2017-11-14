property :listeners,             Array
property :security_groups,       Array
property :subnets,               Array # for VPC networking
property :availability_zones,    Array # for classic networking
property :tags,                  Array
property :scheme,                Array

# authentication
property :aws_access_key,        String
property :aws_secret_access_key, String
property :aws_session_token,     String
property :aws_assume_role_arn,   String
property :aws_role_session_name, String
property :region,                String, default: lazy { fallback_region }

include AwsCookbook::Ec2 # needed for aws_region helper

action :register do
  target_lb = find_elb
  raise "Load balancer #{new_resource.name} not found in #{new_resource.region}" if target_lb.empty?

  if target_lb[:instances].detect { |instance| instance.instance_id == instance_id }
    Chef::Log.debug("Node is already present in ELB #{instance_id}, no action required.")
  else
    converge_by("add node to ELB #{new_resource.name}") do
      elb.register_instances_with_load_balancer(load_balancer_name: new_resource.name, instances: [{ instance_id: instance_id }])
    end
  end
end

action :create do
  if find_elb
    # update logic here
  else
    converge_by "create ELB #{new_resource.name}" do
      create_elb
    end
  end
end

action :delete do
  if elb.describe_load_balancers[:load_balancer_descriptions].find { |lb| lb[:load_balancer_name] == new_resource.name }
    converge_by "delete ELB #{new_resource.name}" do
      elb.delete_load_balancer(load_balancer_name: new_resource.name)
    end
  else
    Chef::Log.debug("Did not find ELB #{new_resource.name} to delete")
  end
end

action :deregister do
  target_lb = find_elb
  if target_lb[:instances].detect { |instance| instance.instance_id == instance_id }
    converge_by("remove node from ELB #{new_resource.name}") do
      elb.deregister_instances_from_load_balancer(load_balancer_name: new_resource.name, instances: [{ instance_id: instance_id }])
    end
  else
    Chef::Log.debug("Node #{instance_id} is not present in ELB instances, no action required.")
  end
end

action_class do
  include AwsCookbook::Ec2

  def elb
    require 'aws-sdk'
    Chef::Log.debug('Initializing the ElasticLoadBalancing Client')
    @elb ||= create_aws_interface(::Aws::ElasticLoadBalancing::Client, region: new_resource.region)
  end

  def find_elb
    elb.describe_load_balancers[:load_balancer_descriptions].find { |lb| lb[:load_balancer_name] == new_resource.name }
  end

  def create_elb
    elb.create_load_balancer(
      listeners: new_resource.listeners,
      load_balancer_name: new_resource.name,
      security_groups: new_resource.security_groups,
      subnets: new_resource.subnets,
      tags: new_resource.tags,
      availability_zones: new_resource.availability_zones
    )
  end
end
