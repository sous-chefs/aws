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
