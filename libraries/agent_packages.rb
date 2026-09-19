# frozen_string_literal: true

module AwsCookbook
  module AgentPackages
    def agent_architecture(machine)
      case machine
      when 'x86_64', 'amd64' then 'amd64'
      when 'aarch64', 'arm64' then 'arm64'
      else raise ArgumentError, "Unsupported AWS agent architecture: #{machine}"
      end
    end

    def agent_package_type(family)
      case family
      when 'debian' then :dpkg_package
      when 'rhel', 'amazon', 'fedora', 'suse' then :rpm_package
      else raise ArgumentError, "Unsupported AWS agent platform family: #{family}"
      end
    end

    def agent_download_url(agent, version, platform, family, machine)
      arch = agent_architecture(machine)
      extension = agent_package_type(family) == :dpkg_package ? 'deb' : 'rpm'
      if agent == 'cloudwatch'
        distribution = if extension == 'rpm'
                         'amazon_linux'
                       else
                         platform == 'ubuntu' ? 'ubuntu' : 'debian'
                       end
        "https://amazoncloudwatch-agent.s3.amazonaws.com/#{distribution}/#{arch}/#{version}/amazon-cloudwatch-agent.#{extension}"
      else
        distribution = extension == 'deb' ? 'debian' : 'linux'
        "https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/#{version}/#{distribution}_#{arch}/amazon-ssm-agent.#{extension}"
      end
    end

    def install_agent_package(agent)
      raise ArgumentError, 'version and checksum are required for :install' unless new_resource.version && new_resource.checksum

      type = agent_package_type(node['platform_family'])
      extension = type == :dpkg_package ? 'deb' : 'rpm'
      agent_architecture(node['kernel']['machine'])
      cache = ::File.join(Chef::Config[:file_cache_path], "amazon-#{agent}-agent.#{extension}")

      remote_file cache do
        source new_resource.source || agent_download_url(agent, new_resource.version, node['platform'], node['platform_family'], node['kernel']['machine'])
        checksum new_resource.checksum
        owner 'root'
        group 'root'
        mode '0600'
      end

      declare_resource(type, "amazon-#{agent}-agent") do
        source cache
        action :install
      end
    end

    def remove_agent_package(agent)
      declare_resource(agent_package_type(node['platform_family']), "amazon-#{agent}-agent") do
        action :remove
      end

      %w(deb rpm).each do |extension|
        file ::File.join(Chef::Config[:file_cache_path], "amazon-#{agent}-agent.#{extension}") do
          action :delete
        end
      end
    end
  end
end
