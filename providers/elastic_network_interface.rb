include Opscode::Aws::Ec2

# Support whyrun
def whyrun_supported?
  true
end

action :attach do
  network_interface_id = new_resource.network_interface_id || node['aws']['elastic_network_interface'][new_resource.name]['network_interface_id']
  device_index = new_resource.device_index || node['aws']['elastic_network_interface'][new_resource.name]['device_index']

  net_interface = get_network_interface(network_interface_id)

  if net_interface.nil?
    fail "Elastic Network Interface #{network_interface_id} does not exist"
  elsif !net_interface[:attachment].nil?
    if net_interface[:attachment][:instance_id] == instance_id
      Chef::Log.debug("Elastic Network Interface #{network_interface_id} is already attached to the instance")
    else
      fail "Elastic Network Interface #{network_interface_id} is attached to another instance"
    end
  else
    converge_by("attach Elastic Network Interface #{network_interface_id} to the instance") do
      Chef::Log.info("Attaching Elastic Network Interface #{network_interface_id} to the instance")
      attach_interface(network_interface_id, device_index, new_resource.timeout)  # attach is idempotent http://docs.aws.amazon.com/sdkforruby/api/Aws/EC2/Client.html#associate_address-instance_method
      node.set['aws']['elastic_network_interface'][new_resource.name]['network_interface_id'] = network_interface_id
      node.save unless Chef::Config[:solo]
    end
  end
end

action :detach do
  network_interface_id = new_resource.network_interface_id || node['aws']['elastic_network_interface'][new_resource.name]['network_interface_id']

  net_interface = get_network_interface(network_interface_id)

  if net_interface.nil?
    Chef::Log.debug("Elastic Network Interface #{network_interface_id} does not exist, so there is nothing to detach")
  elsif net_interface[:attachment].nil? || net_interface[:attachment][:instance_id] != instance_id
    Chef::Log.debug("Elastic Network Interface #{network_interface_id} is already detached from the instance")
  else
    converge_by("detach Elastic Network Interface #{network_interface_id} from the instance") do
      Chef::Log.info("Detaching Elastic Network Interface #{network_interface_id} from the instance")
      detach_interface(network_interface_id, new_resource.timeout)
    end
  end
end

action :create do
  current_elastic_network_interface_id = node['aws']['elastic_network_interface'][new_resource.name]['network_interface_id']
  if current_elastic_network_interface_id
    Chef::Log.info("An Elastic Network Interface was already created for #{new_resource.name} #{current_elastic_ip} from the instance")
  else
    converge_by("create new Elastic Network Interface for #{new_resource.name}") do
      net_interface = ec2.create_network_interface(subnet_id: new_resource.subnet_id, private_ip_addresses: new_resource.private_ip_addresses, groups: new_resource.groups)
      Chef::Log.info("Created Elastic Network Interface #{net_interface[:network_interface_id]} from the instance")
      node.set['aws']['elastic_network_interface'][new_resource.name]['network_interface_id'] = net_interface[:network_interface_id]
      node.set['aws']['elastic_network_interface'][new_resource.name]['device_index'] = net_interface[:network_interface_id][:attachment][:device_index]
      node.save unless Chef::Config[:solo]
    end
  end
end

private

def attach_interface(network_interface_id, device_index, timeout)
  ec2.attach_network_interface(instance_id: instance_id, network_interface_id: network_interface_id, device_index: device_index)

  # block until attached
  begin
    Timeout.timeout(timeout) do
      loop do
        net_interface = get_network_interface(network_interface_id)
        if net_interface.nil?
          fail 'Elastic Network Interface has been deleted while waiting for attachment'
        elsif net_interface[:attachment].nil?
          next
        elsif net_interface[:attachment][:instance_id] != instance_id
          Chef::Log.debug("Elastic Network Interface is currently attached to #{net_interface[:attachment][:instance_id]}")
        else
          Chef::Log.debug('Elastic Network Interface is attached to this instance')
          break
        end
        sleep 3
      end
    end
  rescue Timeout::Error
    raise "Timed out waiting for attachment after #{timeout} seconds"
  end
end

def detach_interface(network_interface_id, timeout)
  net_interface = get_network_interface(network_interface_id)
  ec2.detach_network_interface(attachment_id: net_interface[:attachment][:attachment_id])

  # block until detached
  begin
    Timeout.timeout(timeout) do
      loop do
        net_interface = get_network_interface(network_interface_id)
        if net_interface.nil?
          Chef::Log.debug('Elastic Network Interface has been deleted while waiting for detachment')
          break
        elsif net_interface[:attachment].nil?
          Chef::Log.debug('Elastic Network Interface is detached from this instance')
          break
        elsif net_interface[:attachment][:instance_id] != instance_id
          Chef::Log.debug('Elastic Network Interface is detached from this instance')
          break
        else
          Chef::Log.debug('Elastic Network Interface is still attached')
        end
        sleep 3
      end
    end
  rescue Timeout::Error
    raise "Timed out waiting for detachment after #{timeout} seconds"
  end
end
