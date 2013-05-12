## v0.101.0

### Bug

- [COOK-1355]: AWS::ElasticIP recipe uses an old RightAWS API to
  associate an elastic ip address to an EC2 instance
- [COOK-2659]: `volume_compatible_with_resource_definition` fails on
  valid `snapshot_id` configurations
- [COOK-2670]: AWS cookbook doesn't use `node[:aws][:databag_name]`,
  etc. in `create_raid_disks`
- [COOK-2693]: exclude AWS reserved tags from tag update
- [COOK-2914]: Foodcritic failures in Cookbooks

### Improvement

- [COOK-2587]: Resource attribute for using most recent snapshot
  instead of earliest
- [COOK-2605]: "WARN: Missing gem '`right_aws`'" always prints when
  including 'aws' in metadata

### New Feature

- [COOK-2503]: add EBS raid volumes and provisioned IOPS support for
  AWS

## v0.100.6:

* [COOK-2148] - `aws_ebs_volume` attach action saves nil `volume_id`
  in node

## v0.100.4:

* Support why-run mode in LWRPs
* [COOK-1836] - make `aws_elastic_lb` idempotent

## v0.100.2:

* [COOK-1568] - switch to chef_gem resource
* [COOK-1426] - declare default actions for LWRPs

## v0.100.0:

* [COOK-1221] - convert node attribute accessors to strings
* [COOK-1195] - manipulate AWS resource tags (instances, volumes,
  snapshots
* [COOK-627] - add aws_elb (elastic load balancer) LWRP

## v0.99.1

* [COOK-530] - aws cookbook doesn't save attributes with chef 0.10.RC.0
* [COOK-600] - In AWS Cookbook specifying just the device doesn't work
* [COOK-601] - in aws cookbook :prune action keeps 1 less snapshot than snapshots_to_keep
* [COOK-610] - Create Snapshot action in aws cookbook should allow description attribute
* [COOK-819] - fix documentation bug in aws readme
* [COOK-829] - AWS cookbook does not work with most recent right_aws gem but no version is locked in the recipe
