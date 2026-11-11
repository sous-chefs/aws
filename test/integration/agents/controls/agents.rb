# frozen_string_literal: true

control 'cloudwatch-agent' do
  describe package('amazon-cloudwatch-agent') do
    it { should be_installed }
  end

  %w(chef-config.json chef-config.sha256 amazon-cloudwatch-agent.toml amazon-cloudwatch-agent.yaml).each do |name|
    describe file("/opt/aws/amazon-cloudwatch-agent/etc/#{name}") do
      it { should exist }
      its('owner') { should eq 'root' }
    end
  end

  describe file('/opt/aws/amazon-cloudwatch-agent/etc/chef-config.json') do
    its('mode') { should cmp '0600' }
  end

  describe systemd_service('amazon-cloudwatch-agent') do
    it { should be_enabled }
    it { should_not be_running }
  end
end
