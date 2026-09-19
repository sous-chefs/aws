# frozen_string_literal: true

control 'agents-removed' do
  %w(amazon-cloudwatch-agent amazon-ssm-agent).each do |name|
    describe package(name) do
      it { should_not be_installed }
    end
  end

  %w(
    /opt/aws/amazon-cloudwatch-agent
    /etc/amazon/ssm
    /var/log/amazon/ssm
    /lib/systemd/system/amazon-ssm-agent.service
    /etc/init/amazon-ssm-agent.conf
    /opt/kitchen/cache/amazon-cloudwatch-agent.deb
    /opt/kitchen/cache/amazon-ssm-agent.deb
  ).each do |path|
    describe file(path) do
      it { should_not exist }
    end
  end

  describe directory('/var/lib/amazon/ssm') do
    it { should exist }
  end
end
