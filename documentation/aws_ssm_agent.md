# aws_ssm_agent

Install and configure the Amazon Systems Manager Agent on Linux. This is separate
from `aws_ssm_parameter_store`, which reads and writes Parameter Store through the API.

```ruby
aws_ssm_agent 'default' do
  version '3.3.5226.0'
  checksum node['my_company']['ssm_package_sha256']
  configuration 'Ssm' => { 'Region' => 'eu-west-1' }
  action [:install, :configure, :enable, :start]
end
```

## Properties

| Property | Type | Default | Purpose |
| --- | --- | --- | --- |
| `version` | String | none | Vendor release published to the SSM download bucket. Required for install. |
| `checksum` | String | none | SHA-256 of the package for the target OS and architecture. Required for install. |
| `source` | String | vendor S3 URL | Optional mirror or `file://` package URL. |
| `configuration` | Hash | none | JSON settings for `amazon-ssm-agent.json`. Required for configure; treated as sensitive. |
| `logging_configuration` | String | none | Complete Seelog XML. Required for configure_logging; treated as sensitive. |
| `restart_on_change` | Boolean | `true` | Restart an already-running agent when JSON or logging configuration changes. |

## Actions

* `:install` (default): download, verify and install the selected DEB/RPM package.
* `:configure`: write root-only `/etc/amazon/ssm/amazon-ssm-agent.json`. Install first.
* `:configure_logging`: write root-only `/etc/amazon/ssm/seelog.xml`. Install first.
* `:enable`, `:disable`, `:start`, `:stop`, `:restart`: control the vendor systemd unit.
* `:remove`: stop/disable, uninstall, delete cached packages, `/etc/amazon/ssm` and `/var/log/amazon/ssm`.

Removal retains `/var/lib/amazon/ssm`, including registration and session state.
It does not deregister a managed node from AWS. Deal with that state explicitly as
part of the host's decommissioning procedure. The resource owns one host-wide agent
regardless of the Chef resource name; do not use competing declarations/managers.

The vendor's package scripts may enable/start SSM during installation or upgrades.
Use `action [:install, :configure, :stop, :disable]` if the final state must be stopped
and disabled. Configuration changes restart only an active service; unchanged
configuration does not restart it. Property settings follow the
[vendor's configuration schema and defaults](https://github.com/aws/amazon-ssm-agent#config-property-definitions).

Supports systemd Linux hosts using DEB/RPM packages on x86-64 and ARM64, subject to
[AWS's OS support](https://docs.aws.amazon.com/systems-manager/latest/userguide/operating-systems-and-machine-types.html).
This resource deliberately rejects an existing Snap installation, including on
Ubuntu, before any package, configuration or service mutation. Migrate the Snap
installation explicitly first; AWS advises against running both package types.

The caller supplies the instance profile or hybrid activation/registration and
network access required by Systems Manager. This resource creates no IAM roles,
performs no hybrid activation and sends no AWS registration API calls itself.

## Logging

Manage logging independently of the agent JSON settings:

```ruby
aws_ssm_agent 'logging' do
  logging_configuration <<~XML
    <seelog minlevel="info">
      <outputs formatid="main">
        <rollingfile type="size" filename="/var/log/amazon/ssm/amazon-ssm-agent.log" maxsize="30000000" maxrolls="5" />
      </outputs>
      <formats><format id="main" format="%Date %Time %LEVEL %Msg%n" /></formats>
    </seelog>
  XML
  action :configure_logging
end
```

Supply complete valid XML using the [vendor's logging configuration](https://docs.aws.amazon.com/systems-manager/latest/userguide/ssm-agent-logs.html).
The content is written verbatim. This action does not rewrite `amazon-ssm-agent.json`.
Omitting the action leaves existing logging settings unchanged. Set
`restart_on_change false` to control restarts separately. Removal deletes this file
and logs under `/var/log/amazon/ssm`; custom log destinations elsewhere remain the
caller's responsibility.
