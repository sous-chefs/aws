# frozen_string_literal: true

require 'spec_helper'

describe 'aws_cloudwatch_agent' do
  platform 'ubuntu', '24.04'
  step_into :aws_cloudwatch_agent

  context 'installation' do
    recipe do
      aws_cloudwatch_agent 'default' do
        version '1.300072.0b1766'
        checksum 'a' * 64
      end
    end

    it 'downloads a verified versioned package' do
      expect(chef_run).to create_remote_file("#{Chef::Config[:file_cache_path]}/amazon-cloudwatch-agent.deb")
        .with(checksum: 'a' * 64, mode: '0600')
      expect(chef_run).to install_dpkg_package('amazon-cloudwatch-agent')
      expect(chef_run).not_to start_systemd_unit('amazon-cloudwatch-agent.service')
    end
  end

  context 'configuration' do
    recipe do
      aws_cloudwatch_agent 'default' do
        configuration 'agent' => { 'region' => 'eu-west-1' }
        mode 'onPremise'
        action :configure
      end
    end

    it 'keeps the source separate from the vendor-deleted canonical JSON' do
      expect(chef_run).to create_file('/opt/aws/amazon-cloudwatch-agent/etc/chef-config.json')
        .with(mode: '0600', sensitive: true)
    end

    it 'translates the JSON without starting a stopped agent' do
      command = chef_run.execute('translate CloudWatch agent configuration')
      expect(command.command).to eq(['/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl', '-a', 'fetch-config', '-m', 'onPremise', '-c', 'file:/opt/aws/amazon-cloudwatch-agent/etc/chef-config.json'])
      expect(command).to notify('systemd_unit[amazon-cloudwatch-agent.service]').to(:try_restart).immediately
    end
  end

  context 'removal' do
    recipe { aws_cloudwatch_agent('default') { action :remove } }

    it 'removes the package, generated configuration and download' do
      expect(chef_run).to remove_dpkg_package('amazon-cloudwatch-agent')
      expect(chef_run).to delete_directory('/opt/aws/amazon-cloudwatch-agent')
      expect(chef_run).to delete_file("#{Chef::Config[:file_cache_path]}/amazon-cloudwatch-agent.deb")
    end
  end

  context 'RPM installation on ARM64' do
    platform 'amazon', '2023'
    automatic_attributes['kernel']['machine'] = 'aarch64'
    recipe do
      aws_cloudwatch_agent 'default' do
        version '1.300072.0b1766'
        checksum 'b' * 64
      end
    end

    it 'uses the ARM64 vendor RPM' do
      expect(chef_run).to install_rpm_package('amazon-cloudwatch-agent')
      expect(chef_run).to create_remote_file("#{Chef::Config[:file_cache_path]}/amazon-cloudwatch-agent.rpm")
        .with(source: 'https://amazoncloudwatch-agent.s3.amazonaws.com/amazon_linux/arm64/1.300072.0b1766/amazon-cloudwatch-agent.rpm')
    end
  end

  context 'missing package verification' do
    recipe { aws_cloudwatch_agent 'default' }

    it 'fails before downloading or installing' do
      expect { chef_run }.to raise_error(ArgumentError, /version and checksum are required/)
    end
  end

  context 'missing configuration' do
    recipe { aws_cloudwatch_agent('default') { action :configure } }

    it 'fails before running the vendor translator' do
      expect { chef_run }.to raise_error(ArgumentError, /configuration is required/)
    end
  end

  %i(start stop restart enable disable).each do |service_action|
    context service_action.to_s do
      recipe { aws_cloudwatch_agent('default') { action service_action } }

      it "delegates #{service_action} to systemd" do
        expect(chef_run).to public_send("#{service_action}_systemd_unit", 'amazon-cloudwatch-agent.service')
      end
    end
  end
end
