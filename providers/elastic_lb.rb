include Opscode::Aws::Ec2

action :register do
  converge_by("add the node #{new_resource.name} to ELB") do
    Chef::Log.info("Adding node to ELB #{new_resource.name}")
    elb.register_instances_with_load_balancer(new_resource.name, instance_id)
  end
end

action :deregister do
  converge_by("remove the node #{new_resource.name} from ELB") do
    Chef::Log.info("Removing node from ELB #{new_resource.name}")
    elb.deregister_instances_with_load_balancer(new_resource.name, instance_id)
  end
end

private

def elb
  region = instance_availability_zone
  region = region[0, region.length-1]
  @@elb ||= RightAws::ElbInterface.new(new_resource.aws_access_key, new_resource.aws_secret_access_key, { :logger => Chef::Log, :region => region })
end

