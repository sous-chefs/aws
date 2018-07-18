property :ip,                    String, required: true
property :interface,             String, default: lazy { node['network']['default_interface'] }
property :timeout,               [Integer, nil], default: 3 * 60 # 3 mins, nil or 0 for no timeout

# authentication
property :aws_access_key,        String
property :aws_secret_access_key, String
property :aws_session_token,     String
property :aws_assume_role_arn,   String
property :aws_role_session_name, String
property :region,                String, default: lazy { fallback_region }

include AwsCookbook::Ec2 # needed for aws_region helper

action :assign do
  ip = new_resource.ip
  eni = interface_eni_id(new_resource.interface)
  assigned_addresses = interface_private_ips(new_resource.interface)

  if assigned_addresses.include? ip
    Chef::Log.debug("secondary ip (#{ip}) is already attached to the #{new_resource.interface}")
  else
    converge_by("assign secondary #{ip} to #{new_resource.interface}") do
      assign(eni, ip)

      begin
        Timeout.timeout(new_resource.timeout) do
          # if the IP isn't there then sleep, reload ohai data and check again
          until interface_private_ips(new_resource.interface).include?(new_resource.ip)
            sleep 4

            # make sure ohai has the updated interface information
            ohai 'Reload Ohai EC2 data' do
              action :nothing
              plugin 'ec2'
            end.run_action(:reload)
          end
        end
      rescue Timeout::Error
        raise "Timed out waiting for assignment after #{new_resource.timeout} seconds"
      end
      Chef::Log.debug("Secondary IP #{ip} assigned to #{new_resource.interface}")
    end
  end
end

action :unassign do
  ip = new_resource.ip
  eni = interface_eni_id(new_resource.interface)

  # find the private IP addresses on the interface
  assigned_addresses = interface_private_ips(new_resource.interface)

  if assigned_addresses.include?(ip)
    converge_by("unassign secondary #{ip} from #{new_resource.interface}") do
      unassign(eni, ip)
      begin
        Timeout.timeout(new_resource.timeout) do
          while interface_private_ips(new_resource.interface).include?(new_resource.ip)
            sleep 4

            # make sure ohai has the updated interface information
            ohai 'Reload Ohai EC2 data' do
              action :nothing
              plugin 'ec2'
            end.run_action(:reload)
          end
        end
      rescue Timeout::Error
        raise "Timed out waiting for unassignment after #{timeout} seconds"
      end
      Chef::Log.debug("Secondary IP #{ip} unassigned from #{new_resource.interface}")
    end
  else
    Chef::Log.debug("Secondary IP #{ip} is already detached from the #{new_resource.interface}")
  end
end

action_class do
  include AwsCookbook::Ec2

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

  # fetch the mac address of an interface.
  def interface_mac_address(interface)
    node['network']['interfaces'][interface]['addresses'].select do |_, e|
      e['family'] == 'lladdr'
    end.keys.first.downcase
  end

  # return an array of all private IPs on an interface
  def interface_private_ips(interface)
    mac = interface_mac_address(interface)
    ips = node['ec2']['network_interfaces_macs'][mac]['local_ipv4s']
    ips = ips.split("\n") if ips.is_a? String # ohai 14 will return an array
    Chef::Log.debug("#{interface} assigned local ipv4s addresses is/are #{ips.join(',')}")
    ips
  end

  # return the interface ID given an interface
  def interface_eni_id(interface)
    mac = interface_mac_address(interface)
    eni_id = node['ec2']['network_interfaces_macs'][mac]['interface_id']
    Chef::Log.debug("#{interface} eni id is #{eni_id}")
    eni_id
  end
end
