# frozen_string_literal: true

require 'spec_helper'

describe 'aws_ssm_agent' do
  platform 'ubuntu', '24.04'
  step_into :aws_ssm_agent

  context 'installation' do
    recipe do
      aws_ssm_agent 'default' do
        version '3.3.5226.0'
        checksum 'a' * 64
      end
    end

    it 'installs the verified vendor DEB' do
      expect(chef_run).to create_remote_file("#{Chef::Config[:file_cache_path]}/amazon-ssm-agent.deb").with(checksum: 'a' * 64)
      expect(chef_run).to install_dpkg_package('amazon-ssm-agent')
    end
  end

  context 'RPM on ARM64' do
    platform 'amazon', '2023'
    automatic_attributes['kernel']['machine'] = 'aarch64'
    recipe do
      aws_ssm_agent 'default' do
        version '3.3.5226.0'
        checksum 'b' * 64
      end
    end

    it 'selects the ARM64 RPM' do
      expect(chef_run).to install_rpm_package('amazon-ssm-agent')
      expect(chef_run).to create_remote_file("#{Chef::Config[:file_cache_path]}/amazon-ssm-agent.rpm")
        .with(source: 'https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/3.3.5226.0/linux_arm64/amazon-ssm-agent.rpm')
    end
  end

  context 'configuration' do
    recipe do
      aws_ssm_agent 'default' do
        configuration 'Ssm' => { 'Region' => 'eu-west-1' }
        action :configure
      end
    end

    it 'writes private JSON and restarts only an active service when changed' do
      expect(chef_run).to create_file('/etc/amazon/ssm/amazon-ssm-agent.json')
        .with(content: "{\n  \"Ssm\": {\n    \"Region\": \"eu-west-1\"\n  }\n}\n", mode: '0600', sensitive: true)
      expect(chef_run.file('/etc/amazon/ssm/amazon-ssm-agent.json'))
        .to notify('systemd_unit[amazon-ssm-agent.service]').to(:try_restart).immediately
    end
  end

  %w(/snap/amazon-ssm-agent /var/lib/snapd/snap/amazon-ssm-agent).each do |snap_path|
    context "existing Snap at #{snap_path}" do
      before do
        allow(File).to receive(:directory?).and_call_original
        allow(File).to receive(:directory?).with(snap_path).and_return(true)
      end
      recipe { aws_ssm_agent('default') { action :remove } }

      it 'rejects mutation without uninstalling Snap' do
        expect { chef_run }.to raise_error(ArgumentError, /Snap installation/)
      end
    end
  end

  context 'logging configuration' do
    recipe do
      aws_ssm_agent 'default' do
        logging_configuration '<seelog minlevel="info"><outputs><console /></outputs></seelog>'
        action :configure_logging
      end
    end

    it 'writes private XML and restarts only an active service when changed' do
      expect(chef_run).to create_file('/etc/amazon/ssm/seelog.xml')
        .with(content: '<seelog minlevel="info"><outputs><console /></outputs></seelog>', owner: 'root', mode: '0600', sensitive: true)
      expect(chef_run.file('/etc/amazon/ssm/seelog.xml'))
        .to notify('systemd_unit[amazon-ssm-agent.service]').to(:try_restart).immediately
      expect(chef_run).not_to create_file('/etc/amazon/ssm/amazon-ssm-agent.json')
    end
  end

  context 'logging without automatic restart' do
    recipe do
      aws_ssm_agent 'default' do
        logging_configuration '<seelog minlevel="info"><outputs><console /></outputs></seelog>'
        restart_on_change false
        action :configure_logging
      end
    end

    it 'leaves service state to the caller' do
      expect(chef_run.file('/etc/amazon/ssm/seelog.xml')).not_to notify('systemd_unit[amazon-ssm-agent.service]')
    end
  end

  context 'missing logging configuration' do
    recipe { aws_ssm_agent('default') { action :configure_logging } }

    it 'fails clearly' do
      expect { chef_run }.to raise_error(ArgumentError, /logging_configuration is required/)
    end
  end

  context 'missing configuration' do
    recipe { aws_ssm_agent('default') { action :configure } }

    it 'fails clearly' do
      expect { chef_run }.to raise_error(ArgumentError, /configuration is required/)
    end
  end

  context 'removal' do
    recipe { aws_ssm_agent('default') { action :remove } }

    it 'removes the package and owned configuration while retaining registration state' do
      expect(chef_run).to purge_dpkg_package('amazon-ssm-agent')
      expect(chef_run).to delete_directory('/etc/amazon/ssm')
      expect(chef_run).to delete_file("#{Chef::Config[:file_cache_path]}/amazon-ssm-agent.deb")
      expect(chef_run).not_to delete_directory('/var/lib/amazon/ssm')
    end
  end

  %i(start stop restart enable disable).each do |service_action|
    context service_action.to_s do
      recipe { aws_ssm_agent('default') { action service_action } }

      it "delegates #{service_action} to systemd" do
        expect(chef_run).to public_send("#{service_action}_systemd_unit", 'amazon-ssm-agent.service')
      end
    end
  end
end
