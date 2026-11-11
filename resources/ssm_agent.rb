# frozen_string_literal: true

require 'json'

unified_mode true
provides :aws_ssm_agent

property :version, String, regex: /\A[0-9][0-9a-zA-Z.-]*\z/
property :checksum, String, regex: /\A[0-9a-fA-F]{64}\z/
property :source, String
property :configuration, Hash, sensitive: true
property :restart_on_change, [true, false], default: true

default_action :install

action :install do
  reject_ssm_snap!
  install_agent_package('ssm')
end

action :configure do
  reject_ssm_snap!
  raise ArgumentError, 'configuration is required for :configure' unless new_resource.configuration

  systemd_unit 'amazon-ssm-agent.service' do
    action :nothing
  end

  file '/etc/amazon/ssm/amazon-ssm-agent.json' do
    content JSON.pretty_generate(new_resource.configuration) + "\n"
    owner 'root'
    group 'root'
    mode '0600'
    sensitive true
    notifies :try_restart, 'systemd_unit[amazon-ssm-agent.service]', :immediately if new_resource.restart_on_change
  end
end

%i(start stop restart enable disable).each do |service_action|
  action service_action do
    reject_ssm_snap!
    systemd_unit 'amazon-ssm-agent.service' do
      action service_action
    end
  end
end

action :remove do
  reject_ssm_snap!
  systemd_unit 'amazon-ssm-agent.service' do
    action [:stop, :disable]
    only_if { ::File.exist?('/usr/bin/amazon-ssm-agent') }
  end

  remove_agent_package('ssm')

  %w(/etc/amazon/ssm /var/log/amazon/ssm).each do |path|
    directory path do
      recursive true
      action :delete
    end
  end
end

action_class do
  include AwsCookbook::AgentPackages

  def reject_ssm_snap!
    if ::File.directory?('/snap/amazon-ssm-agent') ||
       ::File.directory?('/var/lib/snapd/snap/amazon-ssm-agent') ||
       ::File.exist?('/var/lib/snapd/sequence/amazon-ssm-agent.json')
      raise ArgumentError, 'An SSM Agent Snap installation exists. Migrate it explicitly before using aws_ssm_agent; DEB/RPM and Snap must not coexist.'
    end
  end
end
