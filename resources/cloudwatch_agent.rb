# frozen_string_literal: true

require 'digest'
require 'json'

unified_mode true
provides :aws_cloudwatch_agent

property :version, String, regex: /\A[0-9][0-9a-zA-Z.-]*\z/
property :checksum, String, regex: /\A[0-9a-fA-F]{64}\z/
property :source, String
property :configuration, Hash, sensitive: true
property :mode, String, equal_to: %w(ec2 onPremise), default: 'ec2'
property :restart_on_change, [true, false], default: true

default_action :install

action :install do
  install_agent_package('cloudwatch')
end

action :configure do
  raise ArgumentError, 'configuration is required for :configure' unless new_resource.configuration

  config_dir = '/opt/aws/amazon-cloudwatch-agent/etc'
  input = "#{config_dir}/chef-config.json"
  receipt = "#{config_dir}/chef-config.sha256"
  content = JSON.pretty_generate(new_resource.configuration) + "\n"
  binary_version = ::File.read('/opt/aws/amazon-cloudwatch-agent/bin/CWAGENT_VERSION') if ::File.exist?('/opt/aws/amazon-cloudwatch-agent/bin/CWAGENT_VERSION')
  fingerprint = Digest::SHA256.hexdigest([content, new_resource.mode, binary_version].join("\n"))

  systemd_unit 'amazon-cloudwatch-agent.service' do
    action :nothing
  end

  file input do
    content content
    owner 'root'
    group 'root'
    mode '0600'
    sensitive true
  end

  file receipt do
    content fingerprint
    owner 'root'
    group 'root'
    mode '0600'
    action :nothing
  end

  execute 'translate CloudWatch agent configuration' do
    command ['/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl', '-a', 'fetch-config', '-m', new_resource.mode, '-c', "file:#{input}"]
    sensitive true
    not_if do
      ::File.exist?(receipt) && ::File.read(receipt) == fingerprint &&
        ::File.exist?("#{config_dir}/amazon-cloudwatch-agent.toml") &&
        ::File.exist?("#{config_dir}/amazon-cloudwatch-agent.yaml")
    end
    notifies :create, "file[#{receipt}]", :immediately
    notifies :try_restart, 'systemd_unit[amazon-cloudwatch-agent.service]', :immediately if new_resource.restart_on_change
  end
end

%i(start stop restart enable disable).each do |service_action|
  action service_action do
    systemd_unit 'amazon-cloudwatch-agent.service' do
      action service_action
    end
  end
end

action :remove do
  systemd_unit 'amazon-cloudwatch-agent.service' do
    action [:stop, :disable]
    only_if { ::File.exist?('/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent') }
  end

  remove_agent_package('cloudwatch')

  directory '/opt/aws/amazon-cloudwatch-agent' do
    recursive true
    action :delete
  end
end

action_class do
  include AwsCookbook::AgentPackages
end
