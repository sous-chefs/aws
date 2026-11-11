# frozen_string_literal: true

require 'spec_helper'
require_relative '../../libraries/agent_packages'

describe AwsCookbook::AgentPackages do
  let(:helper) { Object.new.extend(described_class) }

  %w(x86_64 amd64).each do |machine|
    it "maps #{machine} to amd64" do
      expect(helper.agent_architecture(machine)).to eq('amd64')
    end
  end

  %w(aarch64 arm64).each do |machine|
    it "maps #{machine} to arm64" do
      expect(helper.agent_architecture(machine)).to eq('arm64')
    end
  end

  it 'rejects unsupported architectures' do
    expect { helper.agent_architecture('i386') }.to raise_error(ArgumentError, /Unsupported/)
  end

  it 'rejects unsupported platforms' do
    expect { helper.agent_package_type('windows') }.to raise_error(ArgumentError, /Unsupported/)
  end

  it 'builds a versioned CloudWatch Ubuntu download' do
    expect(helper.agent_download_url('cloudwatch', '1.300072.0', 'ubuntu', 'debian', 'x86_64'))
      .to eq('https://amazoncloudwatch-agent.s3.amazonaws.com/ubuntu/amd64/1.300072.0/amazon-cloudwatch-agent.deb')
  end

  it 'builds a versioned CloudWatch RPM download' do
    expect(helper.agent_download_url('cloudwatch', '1.300072.0', 'amazon', 'amazon', 'aarch64'))
      .to eq('https://amazoncloudwatch-agent.s3.amazonaws.com/amazon_linux/arm64/1.300072.0/amazon-cloudwatch-agent.rpm')
  end

  it 'builds a versioned SSM Debian download' do
    expect(helper.agent_download_url('ssm', '3.3.5390.0', 'debian', 'debian', 'arm64'))
      .to eq('https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/3.3.5390.0/debian_arm64/amazon-ssm-agent.deb')
  end

  it 'builds a versioned SSM RPM download' do
    expect(helper.agent_download_url('ssm', '3.3.5390.0', 'redhat', 'rhel', 'amd64'))
      .to eq('https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/3.3.5390.0/linux_amd64/amazon-ssm-agent.rpm')
  end

  { 'debian' => [:dpkg_package, :purge], 'rhel' => [:rpm_package, :remove] }.each do |family, (type, package_action)|
    it "cleans package-owned configuration on #{family}" do
      allow(helper).to receive(:node).and_return('platform_family' => family)
      allow(helper).to receive(:file)
      expect(helper).to receive(:declare_resource).with(type, 'amazon-ssm-agent') do |*, &block|
        resource = double('package')
        expect(resource).to receive(:action).with(package_action)
        resource.instance_eval(&block)
      end
      helper.remove_agent_package('ssm')
    end
  end
end
