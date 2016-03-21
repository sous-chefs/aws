include Opscode::Aws::Ec2

use_inline_resources

def whyrun_supported?
  true
end

action :assign do
  ip = new_resource.ip
  if node['aws']['secondary_ip'] && node['aws']['secondary_ip'][new_resource.name]
    ip = node['aws']['secondary_ip'][new_resource.name]['ip']
  end

  interface = new_resource.interface || query_default_interface
  eni = query_network_interface_id(interface)
  timeout = new_resource.timeout

  assigned_addreses = query_private_ip_addresses(interface)

  if assigned_addreses.include? ip
    Chef::Log.debug("secondary ip (#{ip}) is already attached to the #{interface}")
  else
    converge_by("assign secondary ip to #{interface}") do
      assign(eni, ip)
      begin
        Timeout.timeout(timeout) do
          loop do
            break if [query_private_ip_addresses(interface)].flatten.count > [assigned_addreses].flatten.count
            sleep 3
          end
        end
      rescue Timeout::Error
        raise "Timed out waiting for assignment after #{timeout} seconds"
      end
      node.set['aws']['secondary_ip'][new_resource.name]['ip'] =
        (query_private_ip_addresses(interface) - assigned_addreses).flatten.first
      node.save unless Chef::Config[:solo]
      Chef::Log.debug("Secondary IP #{ip} assigned to #{interface}")
    end
  end
end

action :unassign do
  ip = new_resource.ip
  if node['aws']['secondary_ip'] && node['aws']['secondary_ip'][new_resource.name]
    ip = node['aws']['secondary_ip'][new_resource.name]['ip']
  end

  interface = new_resource.interface || query_default_interface
  eni = query_network_interface_id(interface)
  timeout = new_resource.timeout

  assigned_addreses = query_private_ip_addresses(interface)

  if assigned_addreses.include? ip
    converge_by("unassign secondary ip frome #{interface}") do
      unassign(eni, ip)
      begin
        Timeout.timeout(timeout) do
          loop do
            break if [assigned_addreses].flatten.count > [query_private_ip_addresses(interface)].flatten.count
            sleep 3
          end
        end
      rescue Timeout::Error
        raise "Timed out waiting for unassignment after #{timeout} seconds"
      end
      node.set['aws']['secondary_ip'][new_resource.name]['ip'] = nil
      node.save unless Chef::Config[:solo]
      Chef::Log.debug("Secondary IP #{ip} unassigned from #{interface}")
    end
  else
    Chef::Log.debug("Secondary IP #{ip} is already detached from the #{interface}")
  end
end

private

def assign(eni_id, ip_address)
  if ip_address
    ec2.assign_private_ip_addresses(
      network_interface_id: eni_id,
      private_ip_addresses: [ip_address]
    )
  else
    ec2.assign_private_ip_addresses(
      network_interface_id: eni_id,
      secondary_private_ip_address_count: 1
    )
  end
end

def unassign(eni_id, ip_address)
  ec2.unassign_private_ip_addresses(
    network_interface_id: eni_id,
    private_ip_addresses: [ip_address]
  )
end
