# AWS agent implementation notes

This is an incremental extension. Existing AWS API resources, their SDK pins and
the legacy EC2 Kitchen suites remain supported independently of host agents.

* Host agents use vendor DEB/RPM packages and systemd. Package architecture is
  explicitly checked: x86-64 and ARM64 only. Vendor OS support still applies.
* Install requires an explicit vendor release and SHA-256 checksum. Package
  metadata supplies the installed version, including vendor revision suffixes.
* ChefSpec loads only this cookbook and its fixture cookbook. Do not scan the
  parent directory or resolve Berkshelf dependencies for unit tests.
* CloudWatch's control script translates JSON to TOML/YAML. `fetch-config`
  without `-s` does not stop/start the service, but deletes the canonical input
  JSON. Keep the cookbook's input at a separate path.
* SSM Snap and DEB installations must never coexist. Reject Snap before mutation.
* No test may enrol an SSM managed node or send metrics to a real AWS account.

Vendor references:

* <https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/download-CloudWatch-Agent-on-EC2-Instance-commandline-first.html>
* <https://github.com/aws/amazon-cloudwatch-agent/blob/main/packaging/dependencies/amazon-cloudwatch-agent-ctl>
* <https://docs.aws.amazon.com/systems-manager/latest/userguide/manually-install-ssm-agent-linux.html>
* <https://docs.aws.amazon.com/systems-manager/latest/userguide/agent-install-ubuntu-64-snap.html>
