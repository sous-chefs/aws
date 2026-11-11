# aws_cloudwatch_agent

Install and configure the unified Amazon CloudWatch Agent for Linux. This is
separate from `aws_cloudwatch`, which manages CloudWatch alarms through the API.

```ruby
aws_cloudwatch_agent 'default' do
  version '1.300072.0b1766'
  checksum node['my_company']['cloudwatch_package_sha256']
  configuration(
    'agent' => { 'region' => 'eu-west-1' },
    'metrics' => { 'metrics_collected' => { 'mem' => { 'measurement' => ['mem_used_percent'] } } }
  )
  action [:install, :configure, :enable, :start]
end
```

## Properties

| Property | Type | Default | Purpose |
| --- | --- | --- | --- |
| `version` | String | none | Vendor download build, including the `b` suffix. Required for install. |
| `checksum` | String | none | SHA-256 of the package for the target OS and architecture. Required for install. |
| `source` | String | vendor S3 URL | Optional mirror or `file://` package URL. |
| `configuration` | Hash | none | Complete CloudWatch JSON configuration. Required for configure; treated as sensitive. |
| `mode` | String | `ec2` | `ec2` or `onPremise`, passed to the vendor translator. |
| `restart_on_change` | Boolean | `true` | Restart a running agent after successful translation. A stopped agent stays stopped. |

## Actions

* `:install` (default): download, verify and install the exact package. It does not configure the agent.
* `:configure`: write root-only JSON and translate/validate it with the vendor tool. Install first.
* `:enable`, `:disable`, `:start`, `:stop`, `:restart`: control the vendor systemd unit.
* `:remove`: stop/disable, remove the package, cached downloads and `/opt/aws/amazon-cloudwatch-agent`, including logs and configuration.

The resource owns one host-wide agent regardless of its Chef resource name.
Do not combine it with another manager of the agent's configuration. Configuration
replaces the vendor's combined configuration; it is not an append operation.
Translation is retried after failure and rerun when the input, mode or installed
binary version changes, or the generated TOML/YAML is missing.

Supports DEB/RPM Linux hosts with systemd on x86-64 and ARM64, subject to the
[vendor's OS support](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/install-CloudWatch-Agent-on-EC2-Instance.html).
The caller supplies AWS permissions and credentials through the agent's normal
credential chain, usually an EC2 instance profile. This resource creates no IAM
roles and embeds no access keys. `onPremise` configuration needs an explicit region
and the credential profile selected by the vendor's `common-config.toml` (normally
`AmazonCloudWatchAgent`), even when the input JSON is local.
Package maintainer scripts retain their vendor-defined service behaviour during upgrades.
