# aws Cookbook CHANGELOG

This file is used to list changes made in each version of the aws cookbook.

## 7.4.0 (2018-05-17)

- Allow installation of either aws-sdk v2 or v3
- Add support for STS assumed roles
- Add default empty hashes to several properties
- Resolve a few more Chef 14 incompatibilities
- Fix a failure when deleting ebs volumes

## 7.3.1 (2018-03-21)

- Check for nil as well as empty tags in ebs_volume

## 7.3.0 (2018-03-20)

- add aws_instance_role
- Add option to tag the new volumes and snapshots
- Added basic functionality for parameter store
- add `requester_pays` option to `s3_file`
- fix etag request via head_object when requester_pays
- Remove name property that isn't necessary
- Added SSM Parameter Store get functionality
- Chef 14: Avoid passing nils to remote_file in aws_s3_file resource

## 7.2.2 (2017-11-14)

- Resolve FC108 warning
- Make sure ip is listed as required for elastic_ip in the readme

## 7.2.1 (2017-09-08)

- Add missing aws_instance_term_protection matcher. Rename kinetic to kinesis matcher.

## 7.2.0 (2017-09-06)

- Add instance_term_protection resource
- Added named_iam_capability option to the cloudformation_stack resource

## 7.1.2 (2017-06-19)

- Multiple fixes to issues with the elastic_ip resource that prevented converges

## 7.1.1 (2017-06-16)

- Use the correct region value to prevent converge failures introduced in 7.0 with the ebs_volume resource
- Better handle snapshots when the user passes a volume_id instead of a snapshot ID
- Reload Ohai data when a ebs volume in attached or detached so the node data is correct
- Properly error if the user does not pass device to ebs_volume when its needed

## 7.1.0 (2017-06-16)

- Refactor and fix the secondary_ip resource
  - Fix failures that occured when assigning IPs via the resource (aka make it actually work)
  - Move all helpers out of the EC2 libary and into the resource itself
  - Instead of using open-uri to query the metadata endpoint use EC2 data from Ohai
  - Make IP a required property since we need that to run
  - Refactor the wait loop that broke notification when the resources updated
  - Reload Ohai data in the resource so downstream recipes will know about the new IP

## 7.0.0 (2017-06-15)

- The route53_record resource from the route53 resource has been moved into this cookbook. The resource is now named aws_route53_record, but can be referenced by the old name: route53_record. The resource now accepts all authentication methods supported by this cookbook and a new zone_name property can be used in place of the zone_id property so you now only need to know the name of the zone the record is placed into.
- Added a new aws_route53_zone resource for adding zones to Route53
- Added new aws_s3_bucket resource. This is a very simple resource at the moment, but it lays the groundwork for a more complex resource for adding buckets with ACLs and other features
- Converted all resources except for dynamodb_table to be custom resources. Logging and converging of resources has been updated and code has been cleaned up
- Simplified the cookbook libraries by collapsing most of the libraries into the individual resources. For the most part these just added unnecessary complexity to the cookbook
- Reworked how aws region information is determined and how the connection to AWS is initialized to work with some the new resources and the existing route53 resources
- Moved the libraries from the Opscode::Aws namespace to the AwsCookbook namespace.
- Large scale readme cleanup. There were multiple resources missing and some resources documented in 2 places. The documentation for resources is now ordered alphabetically and contains all actions and properties.
- Updated elastic_ip resource to reload ohai after changes so ohai data reflects the current node state
- Remove storage of IP information on the node when using the elastic_ip resource. This is a bad practice in general as node data can be changed or deleted by users or chef itself. This is potentially a breaking change for users that relied on this behavior.
- Updated resource_tag to properly support why-run mode

## 6.1.1 (2017-06-05)

- Resolve frozen string warning on Chef 13 in the s3_file rsource
- Resolve useless assignment cookstyle warning in the EC2 library
- Make the ELB deletion messaging consistent with the create messaging

## 6.1.0 (2017-05-01)

- Converted aws_cloudwath and aws_elb to custom resources with code cleanup
- Add create/delete actions to the aws_elb resource. This resource is currently not able to update the state of the ELB and does not setup health checks. It's mostly used to allow us to test the existing attach/detach actions, but it will be expanded in the future to allow for full ELB management
- Cleanup of the EC2 helper and removal of a few unnecessary helpers

## 6.0.0 (2017-04-27)

- Resolve deprecation warning in the chefspecs
- Remove the EBS Raid resource, which did not work on modern EC2 instance types and only worked on select Linux systems. We highly recommend users utilize provisioned IOPS on EBS volumes as they offer far greater reliability. If that's not an option you may want to pin to the 5.X release of this cookbook.
- Remove the ec2_hints recipe as newer Chef releases auto detect EC2 and don't require hints to be applied
- Use Chef's gem install in the metadata to handle gem installation. This increases the minimum required Chef release to 12.9
- Convert instance_monitoring to a custom resource with improved logging and converge notification
- Consider pending to be enabled as well within instance_monitoring to avoid enabling again

## 5.0.1 (2017-04-18)

- Fix for Issue #283 (error on aws_resource_tag): Updated deprecated Chef::Resource call with valid Chef::ResourceResolver drop-in

## 5.0.0 (2017-04-11)

- Calculate the presigned url after the md5 check as it may timeout when the existing file is very large
- Update testing for Chef 13 and use local delivery
- Update apache2 license string
- Require the latest ohai cookbook which fixes Chef 13 compatibility. With this change this cookbook now requires Chef 12.6 or later

## 4.2.2 (2017-02-24)

- Let the API decide what the default volume type is for EBS volumes. This doesn't actually change anything at the moment, but keeps us up to date with the defaults of the aws-sdk

## 4.2.1 (2017-02-24)

- Tweaks to the readme for clarity
- Remove Ubuntu 12.04 and openSUSE 13.2 from Test Kitchen matrix as these are both on the way to EOL
- Remove the sensitive, retries, and retry_delay from the s3_file resource for Chef 13 compatibility since chef itself defines these

## 4.2.0 (2017-01-21)

- README: Add ec2:ModifyInstanceAttribute to sample IAM policy (fixes #241)
- Added a new resource for managing CloudWatch alarms

## 4.1.3 (2016-11-01)

- Dont declare region twice in S3_file

## 4.1.2 (2016-10-04)

- Add matcher definitions for ChefSpec

## 4.1.1 (2016-09-19)

- Fix false "volume no longer exists" errors.
- Use alias_method to cleanup backwards compatibility in s3_file

## 4.1.0 (2016-09-19)

- Pass through retry_delay to remote_file
- Require ohai 4.0+ cookbook and use new compile_time method for ohai_hint resource
- Remove Chef 11 compatibility code in the aws-sdk gem install

## 4.0.0 (2016-09-15)

- Testing updates
- Require Chef 12.1 or later
- Use node.normal instead of node.set to avoid deprecation notices
- Warn in the logs if the default recipe is included
- Remove the ohai reload on every run in the hint recipe
- Remove chef 11 compat in the metadata

## 3.4.1 (2016-08-09)

- Modified find_snapshot_id method to make it work as intended
- Testing framework updates

## v3.4.0 (2016-06-30)

- Added retries property to s3_file
- Switched docker based test kitchen testing to kitchen-dokken
- Added chef_version support metadata
- Added suse, opensuse, and opensuseleap as supported platforms
- Fixed Assume role credentials bug

## v3.3.3 (2016-05-10)

- Add support for new ebs volume types: sc1 st1

## v3.3.2 (2016-04-13)

- Resolved no method error when using the elb resource
- Fixed a bug in the md5 check in the s3_file resource

## v3.3.1 (2016-03-25)

- Only install the aws-sdk gem at compile_time if chef-client supports that

## v3.3.0 (2016-03-25)

- The AWS gem is now automatically installed as needed by the providers
- Added ChefSpec matchers for: cloudformation_stack, dynamodb_table, elastic_lb, iam_*, kinetic_stream, scondary_ip.

## v3.2.0 (2016-03-23)

- Add the :delete action to the ebs_volume provider

## v3.1.0 (2016-03-22)

- Added the sensitive attribute to the s3_file provider
- s3_file provider now compares md5sums of local files against those in S3 to determine if the file should be downloaded during the chef-client run
- s3_file provider now properly handles region by defaulting to us-east-1 unless a region is provided in the resource
- An inspec test suite has been added for the s3_file provider
- s3 connection objects are no longer stored in a per-region hash as this is longer necessary with the changes to how connection objects are stored
- The region method in the S3 module has been removed as it wasn't being used after region handling refactoring in the 3.0 release

## v3.0.0 (2016-03-20)

### Breaking changes:

- Removed the ability to use databags for credentials with the ebs_raid provider. You must now pass the credentials in via the resource, [@tas50]
- [#218] Remove support for Chef < 11.6.0, [@tas50]
- Switched to Ohai to gather information on the AWS instance instead of direct AWS metadata calls. This also removes the node['region'] attribute, which is no longer necessary. If you would like to mock the region for some reason in local testing set `node['ec2']['placement_availability_zone']` to the AZ, as this is used to determine the region, [@tas50]
- aws-sdk gem is no longer loaded in default recipe

### Other Changes

- [#172] Several new features (AWS CloudFormation Support, IAM Support, Kinesis, DynamoDB, and local auth options) [@vancluever]
- Changes the AWS connect to not be shared accross resources. This allows each resource to run against a different region or use different credentials, [@tas50]
- [#63] Add xfs support for ebs_raid filesystem, [@bazbremner]
- Fixed nil default value deprecation warnings in the providers, [@tas50]
- Fixed errors in the ebs_raid provider, [@tas50]
- Fixed missing values in the converge messaging in the ebs_volume provider, [@tas50]
- Fixed a failure when detaching ebs volumes, [@dhui]
- Added use_inline_resources to all providers, [@tas50]

## v2.9.3 (2016-03-07)

- Resolved a default value warning in ebs_raid when running Chef 12.7.2+
- Updated development and testing Gem dependencies
- Resolved the latest rubocop warnings

## v2.9.2 (2016-01-26)

- Fix a missing space in the ohai dependency

## v2.9.1 (2016-01-26)

- Require ohai 2.1.0 or later due to a bug in previous releases that prevented ohai hints from being created
- Added inspec tests for the ohai hint file creation
- Added supported platforms to the metadata so the platform badges will display on the Supermarket

## v2.9.0 (2016-01-26)

- [#191] Add region attribute to s3_file provider, [@zl4bv]
- [#203] Create the ec2 hint using the ohai provider for Windows compatibility, [@tas50]
- [#205] Fix elb register/deregister, [@obazoud]

## v2.8.0 (2016-01-21)

- [#192] Fix secondary_ip failure, add windows support, and document in the readme, [@Scythril]
- [#185] Update the aws-sdk dependency to the 2.2.X release, [@tas50]
- [#189] Loosen the dependency on the aws-sdk to bring in current releases, [@philoserf]
- [#183] Load the aws-sdk gem directly in the providers, [@shortdudey123]
- [#165] Fix encryption support in ebs_raid provider, [@DrMerlin]
- [#190] Add support for AssumeRole granted credentials using the either provided key or an instance profile, [@knorby]
- [#160] Add an attribute to define the region if you're not running in AWS [@ubiquitousthey]
- [#162] Update the Berksfile syntax, [@miketheman]
- Added testing in Travis CI
- Added a Gemfile with testing dependencies
- Added cookbook version and Travis CI status badges to the readme
- Test on the latest Chef releases instead of 11.16.0
- Update contributing and testing documentation
- Add Rakefile for simplified testing
- Add maintainers.md/maintainers.toml files and a Rake task for managing the MD file
- Update provider resources to use the Chef 11+ default_action format

## v2.7.2 (2015-06-29)

- [#124] Retain compatibility with Chef 11, [@dhui]
- [#128] Use correct pageable response from `aws-sdk` v2 update, [@drywheat]
- [#133] Fix ELB registration to detect correctly, deregister fix, [@purgatorio]
- [#154] Update the contributing guide, [@miketheman]
- [#156] Fix `ebs_raid` behavior without a `snapshot_id`, [@mkantor]
- Updates for ignores, use correct supermarket url, [@tas50]

## v2.7.1 (2015-06-04)

- Adding support for aws_session_token

## v2.7.0 (2015-04-06)

- Support for encrypted EBS volumes
- secondary_ip resource and provider
- Improvement of resource_tag id regex
- Add ChefSpec matchers for aws cookbook resources

## v2.6.6 (2015-05-06)

- [#123] Cleans up README and adds more metadata

## v2.6.5 (2015-03-19)

- [#110] Fix `chef_gem` compile time usage, also in conjunction with `chef-sugar` and Chef 11

## v2.6.4 (2015-02-18)

- Reverting all `chef_gem` `compile_time` edits

## v2.6.3 (2015-02-18)

- Fixing `chef_gem` with `Chef::Resource::ChefGem.method_defined?(:compile_time)`

## v2.6.2 (2015-02-18)

- Fixing `chef_gem` for Chef below 12.1.0

## v2.6.1 (2015-02-17)

- Being explicit about usage of the `chef_gem`'s `compile_time` property.
- Eliminating future deprecation warnings in Chef 12.1.0.

## v2.6.0 (2015-02-10)

- Convert to use aws-sdk instead of right_aws

## v2.5.0 (2014-10-22)

- [#60] Updates to CHANGELOG
- [#85] Lots of testing harness goodness
- [#89] Add a recipe to setup ec2 hints in ohai
- [#74] README and CHANGELOG updates
- [#65] Add a resource for enabling CloudWatch Detailed Monitoring
- [#90] Add tests for aws_instance_monitoring

## v2.4.0 (2014-08-07)

- [#64] - force proxy off for metadata queries

## v2.3.0 (2014-07-02)

- Added support for provisioning General Purpose (SSD) volumes (gp2)

## v2.2.2 (2014-05-19)

- [COOK-4655] - Require ec2 gem

## v2.2.0 (2014-04-23)

- [COOK-4500] Support IAM roles for ELB

## v2.1.1 (2014-03-18)

- [COOK-4415] disk_existing_raid resource name inconsistency

## v2.1.0 (2014-02-25)

### Improvement

- **[COOK-4008](https://tickets.opscode.com/browse/COOK-4008)** - Add name property for aws_elastic_ip LWRP

## v2.0.0 (2014-02-19)

- [COOK-2755] Add allocate action to the elastic ip resource
- [COOK-2829] Expose AWS credentials for ebs_raid LWRP as parameters
- [COOK-2935]
- [COOK-4213] Use use_inline_resources
- [COOK-3467] Support IAM role
- [COOK-4344] Add support for mounting existing raids and reusing volume
- [COOK-3859] Add VPC support (allocation_id) to AWS elastic_ip LWRPJoseph Smith

## v1.0.0

### Improvement

- [COOK-2829] - Expose AWS credentials for ebs_raid LWRP as parameters
- Changing attribute defaults begs a major version bump

## v0.101.6

### Bug

- **[COOK-3475](https://tickets.opscode.com/browse/COOK-3475)** - Fix an issue where invoking action detach in the `ebs_volume` provider when the volume is already detached resulted in a failure

## v0.101.4

### Improvement

- **[COOK-3345](https://tickets.opscode.com/browse/COOK-3345)** - Add `aws_s3_file` LWRP
- **[COOK-3264](https://tickets.opscode.com/browse/COOK-3264)** - Allow specifying of file ownership for `ebs_raid` resource `mount_point`

### Bug

- **[COOK-3308](https://tickets.opscode.com/browse/COOK-3308)** - Ensure mdadm properly allocates the device number

## v0.101.2

### Bug

- [COOK-2951]: aws cookbook has foodcritic failures

### Improvement

- [COOK-1471]: aws cookbook should mention the route53 cookbook

## v0.101.0

### Bug

- [COOK-1355]: AWS::ElasticIP recipe uses an old RightAWS API to associate an elastic ip address to an EC2 instance
- [COOK-2659]: `volume_compatible_with_resource_definition` fails on valid `snapshot_id` configurations
- [COOK-2670]: AWS cookbook doesn't use `node[:aws][:databag_name]`, etc. in `create_raid_disks`
- [COOK-2693]: exclude AWS reserved tags from tag update
- [COOK-2914]: Foodcritic failures in Cookbooks

### Improvement

- [COOK-2587]: Resource attribute for using most recent snapshot instead of earliest
- [COOK-2605]: "WARN: Missing gem '`right_aws`'" always prints when including 'aws' in metadata

### New Feature

- [COOK-2503]: add EBS raid volumes and provisioned IOPS support for AWS

## v0.100.6

- [COOK-2148] - `aws_ebs_volume` attach action saves nil `volume_id` in node

## v0.100.4

- Support why-run mode in LWRPs
- [COOK-1836] - make `aws_elastic_lb` idempotent

## v0.100.2

- [COOK-1568] - switch to chef_gem resource
- [COOK-1426] - declare default actions for LWRPs

## v0.100.0

- [COOK-1221] - convert node attribute accessors to strings
- [COOK-1195] - manipulate AWS resource tags (instances, volumes, snapshots
- [COOK-627] - add aws_elb (elastic load balancer) LWRP

## v0.99.1

- [COOK-530] - aws cookbook doesn't save attributes with chef 0.10.RC.0
- [COOK-600] - In AWS Cookbook specifying just the device doesn't work
- [COOK-601] - in aws cookbook :prune action keeps 1 less snapshot than snapshots_to_keep
- [COOK-610] - Create Snapshot action in aws cookbook should allow description attribute
- [COOK-819] - fix documentation bug in aws readme
- [COOK-829] - AWS cookbook does not work with most recent right_aws gem but no version is locked in the recipe

[#110]: https://github.com/chef-cookbooks/aws/issues/110
[#123]: https://github.com/chef-cookbooks/aws/issues/123
[#124]: https://github.com/chef-cookbooks/aws/issues/124
[#128]: https://github.com/chef-cookbooks/aws/issues/128
[#133]: https://github.com/chef-cookbooks/aws/issues/133
[#154]: https://github.com/chef-cookbooks/aws/issues/154
[#156]: https://github.com/chef-cookbooks/aws/issues/156
[#160]: https://github.com/chef-cookbooks/aws/issues/160
[#162]: https://github.com/chef-cookbooks/aws/issues/162
[#165]: https://github.com/chef-cookbooks/aws/issues/165
[#172]: https://github.com/chef-cookbooks/aws/issues/172
[#183]: https://github.com/chef-cookbooks/aws/issues/183
[#185]: https://github.com/chef-cookbooks/aws/issues/185
[#189]: https://github.com/chef-cookbooks/aws/issues/189
[#190]: https://github.com/chef-cookbooks/aws/issues/190
[#191]: https://github.com/chef-cookbooks/aws/issues/191
[#192]: https://github.com/chef-cookbooks/aws/issues/192
[#203]: https://github.com/chef-cookbooks/aws/issues/203
[#205]: https://github.com/chef-cookbooks/aws/issues/205
[#218]: https://github.com/chef-cookbooks/aws/issues/218
[#60]: https://github.com/chef-cookbooks/aws/issues/60
[#63]: https://github.com/chef-cookbooks/aws/issues/63
[#64]: https://github.com/chef-cookbooks/aws/issues/64
[#65]: https://github.com/chef-cookbooks/aws/issues/65
[#74]: https://github.com/chef-cookbooks/aws/issues/74
[#85]: https://github.com/chef-cookbooks/aws/issues/85
[#89]: https://github.com/chef-cookbooks/aws/issues/89
[#90]: https://github.com/chef-cookbooks/aws/issues/90
[@bazbremner]: https://github.com/bazbremner
[@dhui]: https://github.com/dhui
[@drmerlin]: https://github.com/DrMerlin
[@drywheat]: https://github.com/drywheat
[@knorby]: https://github.com/knorby
[@miketheman]: https://github.com/miketheman
[@mkantor]: https://github.com/mkantor
[@obazoud]: https://github.com/obazoud
[@philoserf]: https://github.com/philoserf
[@purgatorio]: https://github.com/purgatorio
[@scythril]: https://github.com/Scythril
[@shortdudey123]: https://github.com/shortdudey123
[@tas50]: https://github.com/tas50
[@ubiquitousthey]: https://github.com/ubiquitousthey
[@vancluever]: https://github.com/vancluever
[@zl4bv]: https://github.com/zl4bv
