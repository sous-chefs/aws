aws Cookbook
============

[![Build Status](https://travis-ci.org/opscode-cookbooks/aws.svg?branch=master)](https://travis-ci.org/opscode-cookbooks/aws)
[![Cookbook Version](https://img.shields.io/cookbook/v/aws.svg)](https://supermarket.chef.io/cookbooks/aws)

This cookbook provides libraries, resources and providers to configure
and manage Amazon Web Services components and offerings with the EC2
API. Currently supported resources:

* EBS Volumes (`ebs_volume`)
* EBS Raid (`ebs_raid`)
* Elastic IPs (`elastic_ip`)
* Elastic Load Balancer (`elastic_lb`)
* AWS Resource Tags (`resource_tag`)
* CloudFormation Stack Management (`cfn_stack`)
* IAM User, Group, Policy, and Role Management:
 * (`iam_user`)
 * (`iam_group`)
 * (`iam_policy`)
 * (`iam_role`)


Unsupported AWS resources that have other cookbooks include but are
not limited to:

* [Route53](http://community.opscode.com/cookbooks/route53)

Requirements
============

Requires Chef 0.7.10 or higher for Lightweight Resource and Provider
support. Chef 0.8+ is recommended. While this cookbook can be used in
`chef-solo` mode, to gain the most flexibility, we recommend using
`chef-client` with a Chef Server.

An Amazon Web Services account is required. The Access Key and Secret
Access Key are used to authenticate with EC2.

AWS Credentials
===============

In order to manage AWS components, authentication credentials need to
be available to the node. There are 3 ways to handle this:

1. explicitly pass credentials parameter to the resource
2. use the credentials in the `~/.aws/credentials` file
3. let the resource pick up credentials from the IAM role assigned to the instance

**Also new** resources can now assume an STS role, with support for MFA as well.
Instructions are below in the relevant section.


## Using resource parameters

To pass the credentials to the resource, credentials should be available to the node.
There are a number of ways to handle this, such as node attributes or Chef roles.

We recommend storing these in a databag (Chef 0.8+), and loading them in the recipe where the
resources are needed.

DataBag recommendation:

    % knife data bag show aws main
    {
      "id": "main",
      "aws_access_key_id": "YOUR_ACCESS_KEY",
      "aws_secret_access_key": "YOUR_SECRET_ACCESS_KEY",
      "aws_session_token": "YOUR_SESSION_TOKEN"
    }

This can be loaded in a recipe with:

    aws = data_bag_item("aws", "main")

And to access the values:

    aws['aws_access_key_id']
    aws['aws_secret_access_key']
    aws['aws_session_token']

We'll look at specific usage below.

## Using local credentials

If credentials are not supplied via parameters, resources will look for the
credentials in the `~/.aws/credentials` file:

```
[default]
aws_access_key_id = ACCESS_KEY_ID
aws_secret_access_key = ACCESS_KEY
```

Note that this also accepts other profiles if they are supplied via the
`ENV['AWS_PROFILE']` environment variable.

## Using IAM instance role

If your instance has an IAM role, then the credentials can be automatically resolved by the cookbook
using Amazon instance metadata API.

You can then omit the resource parameters `aws_secret_access_key` and `aws_access_key`.

Of course, the instance role must have the required policies. Here is a sample policy for EBS volume
management:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:AttachVolume",
        "ec2:CreateVolume",
        "ec2:ModifyVolumeAttribute",
        "ec2:DescribeVolumeAttribute",
        "ec2:DescribeVolumeStatus",
        "ec2:DescribeVolumes",
        "ec2:DetachVolume",
        "ec2:EnableVolumeIO"
      ],
      "Sid": "Stmt1381536011000",
      "Resource": [
        "*"
      ],
      "Effect": "Allow"
    }
  ]
}
```

For resource tags:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:CreateTags",
        "ec2:DescribeTags"
      ],
      "Sid": "Stmt1381536708000",
      "Resource": [
        "*"
      ],
      "Effect": "Allow"
    }
  ]
}
```

## Assuming roles via STS and using MFA

The following is an example of how roles can be assumed using MFA. The following
can also be used to assumes roles that do not require MFA, just ensure that the
MFA arguments (`serial_number` and `token_code`) are omitted.

This assumes you have also stored the `cfn_role_arn`, and `mfa_serial`
attributes as well, but there are plenty of ways these attributes can be
supplied (they could be stored locally in the consuming cookbook, for example).

Note that MFA codes cannot be recycled, hence the importance of creating a
single STS session and passing that to resources. If multiple roles need to
be assumed using MFA, it is probably prudent that these be broken up into
different recipes and `chef-client` runs.

```
require 'aws-sdk'
require 'securerandom'

session_id = SecureRandom.hex(8)
sts = ::Aws::AssumeRoleCredentials.new(
  client: ::Aws::STS::Client.new(
    credentials: ::Aws::Credentials.new(
      node['aws']['aws_access_key_id'],
      node['aws']['aws_secret_access_key']
    ),
    region: 'us-east-1'
  ),
  role_arn: node['aws']['cfn_role_arn'],
  role_session_name: session_id,
  serial_number: node['aws']['mfa_serial'],
  token_code: node['aws']['mfa_code']
)

aws_cfn_stack 'kitchen-test-stack' do
  action :create
  template_source 'kitchen-test-stack.tpl'
  aws_access_key sts.access_key_id
  aws_secret_access_key sts.secret_access_key
  aws_session_token sts.session_token
end
```

When running the cookbook, ensure that an attribute JSON is passed that supplies
the MFA code. Example using chef-zero:

```
echo '{ "aws": { "mfa_code": "123456" } }' > mfa.json && chef-client -z -o 'recipe[aws_test]' -j mfa.json
```

## Running outside of an AWS instance

`region` can be specified if the cookbook is being run outside of an AWS instance.
This can prevent some kinds of failures that happen when resources try to detect
region.

```
aws_cfn_stack 'kitchen-test-stack' do
  action :create
  template_source 'kitchen-test-stack.tpl'
  region 'us-east-1'
end
```


Recipes
=======

default.rb
----------

The default recipe installs the `aws-sdk` RubyGem, which this
cookbook requires in order to work with the EC2 API. Make sure that
the aws recipe is in the node or role `run_list` before any resources
from this cookbook are used.

    "run_list": [
      "recipe[aws]"
    ]

The `gem_package` is created as a Ruby Object and thus installed
during the Compile Phase of the Chef run.

ec2_hints.rb
------------

This recipe is used to setup the ec2 hints for ohai in the case that an
instance is not created using knife-ec2.

Libraries
=========

The cookbook has a library module, `Opscode::AWS::Ec2`, which can be
included where necessary:

    include Opscode::Aws::Ec2

This is needed in any providers in the cookbook. Along with some
helper methods used in the providers, it sets up a class variable,
`ec2` that is used along with the access and secret access keys

Resources and Providers
=======================

This cookbook provides two resources and corresponding providers.

## ebs_volume.rb


Manage Elastic Block Store (EBS) volumes with this resource.

Actions:

* `create` - create a new volume.
* `attach` - attach the specified volume.
* `detach` - detach the specified volume.
* `snapshot` - create a snapshot of the volume.
* `prune` - prune snapshots.

Attribute Parameters:

* `aws_secret_access_key`, `aws_access_key` and optionally `aws_session_token` - passed to
  `Opscode::AWS:Ec2` to authenticate required, unless using IAM roles for authentication.
* `size` - size of the volume in gigabytes.
* `snapshot_id` - snapshot to build EBS volume from.
* most_recent_snapshot - use the most recent snapshot when creating a
   volume from an existing volume (defaults to false)
* `availability_zone` - EC2 region, and is normally automatically
  detected.
* `device` - local block device to attach the volume to, e.g.
  `/dev/sdi` but no default value, required.
* `volume_id` - specify an ID to attach, cannot be used with action
  `:create` because AWS assigns new volume IDs
* `timeout` - connection timeout for EC2 API.
* `snapshots_to_keep` - used with action `:prune` for number of
  snapshots to maintain.
* `description` - used to set the description of an EBS snapshot
* `volume_type` - "standard", "io1", or "gp2" ("standard" is magnetic, "io1" is piops SSD, "gp2" is general purpose SSD)
* `piops` - number of Provisioned IOPS to provision, must be >= 100
* `existing_raid` - whether or not to assume the raid was previously assembled on existing volumes (default no)
* `encrypted` - specify if the EBS should be encrypted
* `kms_key_id` - the full ARN of the AWS Key Management Service (AWS KMS) master key to use when creating the encrypted volume (defaults to master key if not specified)

## ebs_raid.rb

Manage Elastic Block Store (EBS) raid devices with this resource.

Attribute Parameters:

* `aws_secret_access_key`, `aws_access_key` and optionally `aws_session_token` - passed to
  `Opscode::AWS:Ec2` to authenticate, required.
* `mount_point` - where to mount the RAID volume
* `mount_point_owner` - the owner of the mount point (default root)
* `mount_point_group` - the group of the mount point (default root)
* `mount_point_mode` - the file mode of the mount point (default 0755)
* `disk_count` - number of EBS volumes to raid
* `disk_size` - size of EBS volumes to raid
* `level` - RAID level (default 10)
* `filesystem` - filesystem to format raid array (default ext4)
* `snapshots` - array of EBS snapshots to restore. Snapshots must be
  taken using an ec2 consistent snapshot tool, and tagged with a
  number that indicates how many devices are in the array being backed
  up (e.g. "Logs Backup [0-4]" for a four-volume raid array snapshot)
* `disk_type` - "standard" or "io1" (io1 is the type for IOPS volume)
* `disk_piops` - number of Provisioned IOPS to provision per disk,
  must be > 100

## elastic_ip.rb

Actions:

* `associate` - associate the IP.
* `disassociate` - disassociate the IP.

Attribute Parameters:

* `aws_secret_access_key`, `aws_access_key` and optionally `aws_session_token` - passed to
  `Opscode::AWS:Ec2` to authenticate, required, unless using IAM roles for authentication.
* `ip` - the IP address.
* `timeout` - connection timeout for EC2 API.

## elastic_lb.rb

Actions:

* `register` - Add this instance to the LB
* `deregister` - Remove this instance from the LB

Attribute Parameters:

* `aws_secret_access_key`, `aws_access_key` and optionally `aws_session_token` - passed to
  `Opscode::AWS:Ec2` to authenticate, required, unless using IAM roles for authentication.
* `name` - the name of the LB, required.

## resource_tag.rb

Actions:

* `add` - Add tags to a resource.
* `update` - Add or modify existing tags on a resource -- this is the
  default action.
* `remove` - Remove tags from a resource, but only if the specified
  values match the existing ones.
* `force_remove` - Remove tags from a resource, regardless of their
  values.

Attribute Parameters

* `aws_secret_access_key`, `aws_access_key` and optionally `aws_session_token` - passed to
  `Opscode::AWS:Ec2` to authenticate, required, unless using IAM roles for authentication.
* `tags` - a hash of key value pairs to be used as resource tags,
  (e.g. `{ "Name" => "foo", "Environment" => node.chef_environment
  }`,) required.
* `resource_id` - resources whose tags will be modified. The value may
  be a single ID as a string or multiple IDs in an array. If no
  `resource_id` is specified the name attribute will be used.

## instance_monitoring.rb

Actions:

* `enable` - Enable detailed CloudWatch monitoring for this instance (Default).
* `disable` - Disable detailed CloudWatch monitoring for this instance.

Attribute Parameters:

* `aws_secret_access_key`, `aws_access_key` and optionally `aws_session_token` - passed to
  `Opscode::AWS:Ec2` to authenticate, required, unless using IAM roles for authentication.

Usage
=====

The following examples assume that the recommended data bag item has
been created and that the following has been included at the top of
the recipe where they are used.

    include_recipe "aws"
    aws = data_bag_item("aws", "main")

## aws_ebs_volume

The resource only handles manipulating the EBS volume, additional
resources need to be created in the recipe to manage the attached
volume as a filesystem or logical volume.

    aws_ebs_volume "db_ebs_volume" do
      aws_access_key aws['aws_access_key_id']
      aws_secret_access_key aws['aws_secret_access_key']
      size 50
      device "/dev/sdi"
      action [ :create, :attach ]
    end

This will create a 50G volume, attach it to the instance as `/dev/sdi`.

    aws_ebs_volume "db_ebs_volume_from_snapshot" do
      aws_access_key aws['aws_access_key_id']
      aws_secret_access_key aws['aws_secret_access_key']
      size 50
      device "/dev/sdi"
      snapshot_id "snap-ABCDEFGH"
      action [ :create, :attach ]
    end

This will create a new 50G volume from the snapshot ID provided and
attach it as `/dev/sdi`.

## aws_elastic_ip

The `elastic_ip` resource provider does not support allocating new
IPs. This must be done before running a recipe that uses the resource.
After allocating a new Elastic IP, we recommend storing it in a
databag and loading the item in the recipe.

Databag structure:

    % knife data bag show aws eip_load_balancer_production
    {
      "id": "eip_load_balancer_production",
      "public_ip": "YOUR_ALLOCATED_IP"
    }

Then to set up the Elastic IP on a system:

    ip_info = data_bag_item("aws", "eip_load_balancer_production")

    aws_elastic_ip "eip_load_balancer_production" do
      aws_access_key aws['aws_access_key_id']
      aws_secret_access_key aws['aws_secret_access_key']
      ip ip_info['public_ip']
      action :associate
    end

This will use the loaded `aws` and `ip_info` databags to pass the
required values into the resource to configure. Note that when
associating an Elastic IP to an instance, connectivity to the instance
will be lost because the public IP address is changed. You will need
to reconnect to the instance with the new IP.

You can also store this in a role as an attribute or assign to the
node directly, if preferred.

## aws_elastic_lb

`elastic_lb` opererates similar to `elastic_ip'. Make sure that you've
created the ELB and enabled your instances' availability zones prior
to using this provider.

For example, to register the node in the 'QA' ELB:

    aws_elastic_lb "elb_qa" do
      aws_access_key aws['aws_access_key_id']
      aws_secret_access_key aws['aws_secret_access_key']
      name "QA"
      action :register
    end

## aws_resource_tag

`resource_tag` can be used to manipulate the tags assigned to one or
more AWS resources, i.e. ec2 instances, ebs volumes or ebs volume
snapshots.

Assigning tags to a node to reflect it's role and environment:

    aws_resource_tag node['ec2']['instance_id'] do
      aws_access_key aws['aws_access_key_id']
      aws_secret_access_key aws['aws_secret_access_key']
      tags({"Name" => "www.example.com app server",
            "Environment" => node.chef_environment})
      action :update
    end

Assigning a set of tags to multiple resources, e.g. ebs volumes in a
disk set:

    aws_resource_tag 'my awesome raid set' do
      aws_access_key aws['aws_access_key_id']
      aws_secret_access_key aws['aws_secret_access_key']
      resource_id [ "vol-d0518cb2", "vol-fad31a9a", "vol-fb106a9f", "vol-74ed3b14" ]
      tags({"Name" => "My awesome RAID disk set",
            "Environment" => node.chef_environment})
    end

**Note** If you would like to use the normal attribute
   `node['aws']['ebs_volume']['db_ebs_volume']['volume_id']` generated by the
   aws_ebs_volume resource examples above as input for the resource_id attribute of
   the aws_resource_tag resource, you must employ the "lazy" attribute feature
   from Chef 10.28 or Chef 11.x and higher. "lazy" will delay the
   evaluation of the resource_id attribute's value until the normal/set node attribute is
   available.

``` ruby
aws_resource_tag "db_ebs_volume" do
  resource_id lazy { node['aws']['ebs_volume']['db_ebs_volume']['volume_id'] }
  tags ({"Service" => "Frontend"})
end
```

## aws_s3_file

`s3_file` can be used to download a file from s3 that requires aws authorization.  This
is a wrapper around `remote_file` and supports the same resource attributes as `remote_file`.

    aws_s3_file "/tmp/foo" do
      bucket "i_haz_an_s3_buckit"
      remote_path "path/in/s3/bukket/to/foo"
      aws_access_key_id aws['aws_access_key_id']
      aws_secret_access_key aws['aws_secret_access_key']
    end


## aws_instance_monitoring

Allows detailed CloudWatch monitoring to be enabled for the current instance.

    aws_instance_monitoring "enable detailed monitoring"


## aws_cfn_stack

Manage CloudFormation stacks with Chef!

Example:

```
aws_cfn_stack 'example-stack' do
  region 'us-east-1'
  template_source 'example-stack.tpl'

  parameters ([
    {
      :parameter_key => 'KeyPair',
      :parameter_value => 'user@host'
    },
    {
      :parameter_key => 'SSHAllowIPAddress',
      :parameter_value => '127.0.0.1/32'
    }
  ])
end
```

Actions:

 * `create`: Creates the stack, or updates it if it already exists.
 * `delete`: Begins the deletion process for the stack.

Attribute parameters are:

 * `template_source`: Required - the location of the CloudFormation template file.
    The file should be stored in the `files` directory in the cookbook.
 * `parameters`: An array of `parameter_key` and `parameter_value` pairs for
   parameters in the template. Follow the syntax in the example above.
 * `disable_rollback`: Set this to `true` if you want stack rollback to be disabled
   if creation of the stack fails. Default: `false`
 * `stack_policy_body`: Optionally define a stack policy to apply to the stack,
   mainly used in protecting stack resources after they are created. For more
   information, see [Prevent Updates to Stack Resources](http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/protect-stack-resources.html)
   in the CloudFormation user guide.


## aws_iam_user

Use this resource to manage IAM users.

```
aws_iam_user 'example-user' do
  action :create
  path '/'
end
```

Actions:

 * `create`: Creates the user. No effect if the user already exists.
 * `delete`: Gracefully deletes the user (detatches from all attached entities,
   and deletes the user).

The IAM user takes the name of the resource. A `path` can be specified as well.
For more information about paths, see
[IAM Identifiers](http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/protect-stack-resources.html)
in the Using IAM guide.


## aws_iam_group

Use this resource to manage IAM groups. The group takes the name of the resource.

```
aws_iam_group 'example-group' do
  action :create
  path '/'
  members [
    'example-user'
  ]
  remove_members true
  policy_members [
    'arn:aws:iam::123456789012:policy/example-policy'
  ]
  remove_policy_members true
end
```

Actions:

* `create`: Creates the group, and updates members and attached policies if the
  group already exists.
* `delete`: Gracefully deletes the group (detatches from all attached entities,
  and deletes the group).


Attribute parameters are:

 * `path`: A path can be supplied for the group. For information on paths, see
   [IAM Identifiers](http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/protect-stack-resources.html)
   in the Using IAM guide.
 * `members`: An array of IAM users that are a member of this group.
 * `remove_members`: Set to `false` to ensure that members are not removed from
   the group when they are not present in the defined resource. Default: `true`
 * `policy_members`: An array of ARNs of IAM managed policies to attach to this
   resource. Accepts both user-defined and AWS-defined policy ARNs.
 * `remove_policy_members`: Set to `false` to ensure that policies are not
   detached from the group when they are not present in the defined resource.
   Default: `true`


## aws_iam_policy

Use this resource to create an IAM policy. The policy takes the name of the
resource.

```
aws_iam_policy 'example-policy' do
  action :create
  path '/'
  account_id '123456789012'
  policy_document <<-EOH.gsub(/^ {4}/, '')
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Sid": "Stmt1234567890",
                "Effect": "Allow",
                "Action": [
                    "sts:AssumeRole"
                ],
                "Resource": [
                    "arn:aws:iam::123456789012:role/example-role"
                ]
            }
        ]
    }
  EOH
end
```

Actions:

* `create`: Creates or updates the policy.
* `delete`: Gracefully deletes the policy (detatches from all attached entities,
  deletes all non-default policy versions, then deletes the policy).


Attribute parameters are:

 * `path`: A path can be supplied for the group. For information on paths, see
   [IAM Identifiers](http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/protect-stack-resources.html)
   in the Using IAM guide.
 * `policy_document`: The JSON document for the policy.
 * `account_id`: The AWS account ID that the policy is going in. Required if
   using non-user credentials (ie: IAM role through STS or instance role).


## aws_iam_role

Use this resource to create an IAM role. The policy takes the name of the
resource.

```
aws_iam_role 'example-role' do
  action :create
  path '/'
  policy_members [
    'arn:aws:iam::123456789012:policy/example-policy'
  ]
  remove_policy_members true
  assume_role_policy_document <<-EOH.gsub(/^ {4}/, '')
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Sid": "",
          "Effect": "Deny",
          "Principal": {
            "AWS": "*"
          },
          "Action": "sts:AssumeRole"
        }
      ]
    }
  EOH
end
```

* `create`: Creates the role if it does not exist. If the role exists, updates
  attached policies and the `assume_role_policy_document`.
* `delete`: Gracefully deletes the role (detatches from all attached entities,
  and deletes the role).

Attribute parameters are:

 * `path`: A path can be supplied for the group. For information on paths, see
   [IAM Identifiers](http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/protect-stack-resources.html)
   in the Using IAM guide.
 * `policy_members`: An array of ARNs of IAM managed policies to attach to this
   resource. Accepts both user-defined and AWS-defined policy ARNs.
 * `remove_policy_members`: Set to `false` to ensure that policies are not
   detached from the group when they are not present in the defined resource.
   Default: `true`
 * `assume_role_policy_document`: The JSON policy document to apply to this role
   for trust relationships. Dictates what entities can assume this role.


License and Author
==================

* Author:: Chris Walters (<cw@chef.io>)
* Author:: AJ Christensen (<aj@chef.io>)
* Author:: Justin Huff (<jjhuff@mspin.net>)

Copyright 2009-2015, Chef Software, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
