property :aws_access_key,        String
property :aws_secret_access_key, String
property :aws_session_token,     String
property :aws_assume_role_arn,   String
property :aws_role_session_name, String
property :region,                String, default: lazy { aws_region }
property :ip,                    String, name_property: true
property :timeout,               default: 3 * 60 # 3 mins, nil or 0 for no timeout

include AwsCookbook::Ec2 # needed for aws_region helper

action :associate do
  addr = address(new_resource.ip)

  raise "Elastic IP #{ip} does not exist" if addr.nil?

  if addr[:instance_id] == instance_id
    Chef::Log.debug("Elastic IP #{ip} is already attached to the instance")
  else
    converge_by("attach Elastic IP #{ip} to the instance") do
      attach(ip, new_resource.timeout)

      ohai 'Reload Ohai EC2 data' do
        action :reload
        plugin 'ec2'
      end
    end
  end
end

action :disassociate do
  addr = address(new_resource.ip)

  if addr.nil?
    Chef::Log.debug("Elastic IP #{ip} does not exist, so there is nothing to detach")
  elsif addr[:instance_id] != instance_id
    Chef::Log.debug("Elastic IP #{ip} is already detached from the instance")
  else
    converge_by("detach Elastic IP #{ip} from the instance") do
      detach(ip, new_resource.timeout)

      ohai 'Reload Ohai EC2 data' do
        action :reload
        plugin 'ec2'
      end
    end
  end
end

action_class do
  include AwsCookbook::Ec2

  def address(ip)
    ec2.describe_addresses(public_ips: [ip]).addresses[0]
  end

  def attach(ip, timeout)
    addr = address(ip)
    if addr[:domain] == 'vpc'
      ec2.associate_address(instance_id: instance_id, allocation_id: addr[:allocation_id])
    else
      ec2.associate_address(instance_id: instance_id, public_ip: addr[:public_ip])
    end

    # block until attached
    begin
      Timeout.timeout(timeout) do
        loop do
          addr = address(ip)
          if addr.nil?
            raise 'Elastic IP has been deleted while waiting for attachment'
          elsif addr[:instance_id] == instance_id
            Chef::Log.debug('Elastic IP is attached to this instance')
            break
          else
            Chef::Log.debug("Elastic IP is currently attached to #{addr[:instance_id]}")
          end
          sleep 3
        end
      end
    rescue Timeout::Error
      raise "Timed out waiting for attachment after #{timeout} seconds"
    end
  end

  def detach(ip, timeout)
    addr = address(ip)
    if ip[:domain] == 'vpc'
      ec2.disassociate_address(allocation_ip: addr[:allocation_id])
    else
      ec2.disassociate_address(public_ip: ip)
    end

    # block until detached
    begin
      Timeout.timeout(timeout) do
        loop do
          addr = address(ip)
          if addr.nil?
            Chef::Log.debug('Elastic IP has been deleted while waiting for detachment')
          elsif addr[:instance_id] != instance_id
            Chef::Log.debug('Elastic IP is detached from this instance')
            break
          else
            Chef::Log.debug('Elastic IP is still attached')
          end
          sleep 3
        end
      end
    rescue Timeout::Error
      raise "Timed out waiting for detachment after #{timeout} seconds"
    end
  end
end
