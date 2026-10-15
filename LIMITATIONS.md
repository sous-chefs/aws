# AWS Cookbook Limitations

This cookbook manages AWS APIs directly. It does not install vendor packages or configure platform-native services, so package availability and init-system concerns do not apply in the same way they do for service cookbooks.

## Supported Test Surface

- The default Dokken suite and CI matrix retain the existing Linux platforms; cookbook metadata retains the previously advertised platform families
- Live AWS acceptance uses Ubuntu 24.04; Windows and FreeBSD support remains advertised but is not covered by the Linux Dokken matrix
- Standard CI uses local SDK stub responses and Dokken for fast validation
- Live AWS validation is split into a manually triggered workflow backed by repository secrets

## Runtime Constraints

- Real AWS actions require valid credentials with permissions appropriate to each managed resource
- Some live suites need additional environment-specific values such as `AWS_VPC_ID`, `AWS_ELASTIC_IP`, and S3 bucket names
- `aws_ebs_volume` no longer persists volume IDs to node data; cross-run attachment/deletion flows should supply `volume_id` explicitly or rely on device discovery during the same Chef run
