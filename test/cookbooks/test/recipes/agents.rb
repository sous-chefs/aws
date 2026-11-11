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
  content "[AmazonCloudWatchAgent]\naws_access_key_id = offline-test\naws_secret_access_key = offline-test\nregion = eu-west-1\n[default]\naws_access_key_id = offline-test\naws_secret_access_key = offline-test\nregion = eu-west-1\n"
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

aws_ssm_agent 'default' do
  version '3.3.5226.0'
  source 'file:///opt/agent-packages/amazon-ssm-agent.deb'
  checksum node['kernel']['machine'] == 'aarch64' ? '2ed75ecacf633af8b48568f1d468a4849ad006ff901f63761ecb9b0daa8d90d2' : '777df4e0ac4bbc8d7d1b159db76cdb6614666bcc73141874414b8be68fb9cba3'
  configuration(
    'Ssm' => { 'Region' => 'eu-west-1' },
    'Identity' => {
      'ConsumptionOrder' => ['CustomIdentity'],
      'CustomIdentities' => [{ 'InstanceID' => 'i-00000000000000000', 'Region' => 'eu-west-1', 'CredentialsProvider' => 'default' }],
    }
  )
  logging_configuration <<~XML
    <seelog minlevel="info">
      <outputs formatid="main">
        <rollingfile type="size" filename="/var/log/amazon/ssm/chef-test.log" maxsize="1048576" maxrolls="2" />
      </outputs>
      <formats><format id="main" format="%Date %Time %LEVEL %Msg%n" /></formats>
    </seelog>
  XML
  action [:install, :configure, :configure_logging, :enable, :start]
end
