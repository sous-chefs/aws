# frozen_string_literal: true

# Packages are downloaded before the network-isolated Kitchen run.
cloudwatch_checksum = case node['kernel']['machine']
                      when 'aarch64' then 'f84cbb6b193f80440f713ec3a2b2b6ed45a16f10d8f0fe38c01cbff9155cb3f9'
                      when 'x86_64' then '05baeadca96c4bb8e43906ed09cf0bebd0f321ff6d41987bdc46ce681de0978d'
                      end

# The vendor downloader requires a local credential profile even for file input
# in onPremise mode. These deliberately invalid credentials never leave the
# internal Docker network.
directory '/root/.aws' do
  mode '0700'
end

file '/root/.aws/credentials' do
  content "[AmazonCloudWatchAgent]\naws_access_key_id = offline-test\naws_secret_access_key = offline-test\nregion = eu-west-1\n"
  mode '0600'
  sensitive true
end

aws_cloudwatch_agent 'default' do
  version '1.300072.0b1766'
  source 'file:///opt/agent-packages/amazon-cloudwatch-agent.deb'
  checksum cloudwatch_checksum
  configuration(
    'agent' => { 'region' => 'eu-west-1', 'omit_hostname' => true },
    'metrics' => { 'metrics_collected' => { 'mem' => { 'measurement' => ['mem_used_percent'] } } }
  )
  mode 'onPremise'
  action [:install, :configure, :enable]
end
