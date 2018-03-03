# aws Cookbook

[![Build Status](https://travis-ci.org/chef-cookbooks/aws.svg?branch=master)](https://travis-ci.org/chef-cookbooks/aws) [![Cookbook Version](https://img.shields.io/cookbook/v/aws.svg)](https://supermarket.chef.io/cookbooks/aws)

This cookbook provides resources for configuring and managing nodes running in Amazon Web Services as well as several AWS service offerings. Included resources:

- CloudFormation Stack Management (`cloudformation_stack`)
- CloudWatch (`cloudwatch`)
- CloudWatch Instance Monitoring (`instance_monitoring`)
- DynamoDB (`dynamodb_table`)
- EBS Volumes (`ebs_volume`)
- EC2 Instance Role (`instance_role`)
- EC2 Instance Termination Protection (`instance_term_protection`)
- Elastic IPs (`elastic_ip`)
- Elastic Load Balancer (`elastic_lb`)
- IAM User, Group, Policy, and Role Management: (`iam_user`, `iam_group`, `iam_policy`, `iam_role`)
- Kinesis Stream Management (`kinesis_stream`)
- Resource Tags (`resource_tag`)
- Route53 DNS Records (`route53_record`)
- Route53 DNS Zones (`route53_zone`)
- S3 Files (`s3_file`)
- S3 Buckets (`s3_bucket`)
- Secondary IPs (`secondary_ip`)
- AWS SSM Parameter Store ('ssm_parameter_store')

Unsupported AWS resources that have other cookbooks include but are not limited to:

- [aws_security](https://supermarket.chef.io/cookbooks/aws_security)

## Requirements

### Platforms

- Any platform supported by Chef and the AWS-SDK

### Chef

- Chef 12.9+

### Cookbooks

- None

## Credentials

In order to manage AWS components, authentication credentials need to be available to the node. There are 3 ways to handle this:

1. Explicitly set the credentials when using the resources
2. Use the credentials in the `~/.aws/credentials` file
3. Let the resource pick up credentials from the IAM role assigned to the instance

**Also new** resources can now assume an STS role, with support for MFA as well. Instructions are below in the relevant section.

### Using resource parameters

In order to pass the credentials to the resource, credentials must be available to the node. There are a number of ways to handle this, such as node attributes applied to the node or via Chef roles/environments.

We recommend storing these in an encrypted databag, and loading them in the recipe where the resources are used.

Example Data Bag:

```json
% knife data bag show aws main
{
  "id": "main",
  "aws_access_key_id": "YOUR_ACCESS_KEY",
  "aws_secret_access_key": "YOUR_SECRET_ACCESS_KEY",
  "aws_session_token": "YOUR_SESSION_TOKEN"
}
```

This can be loaded in a recipe with:

```ruby
aws = data_bag_item('aws', 'main')
```

And to access the values:

```ruby
aws['aws_access_key_id']
aws['aws_secret_access_key']
aws['aws_session_token']
```

We'll look at specific usage below.

### Using local credentials

If credentials are not supplied via parameters, resources will look for the credentials in the `~/.aws/credentials` file:

```
[default]
aws_access_key_id = ACCESS_KEY_ID
aws_secret_access_key = ACCESS_KEY
```

Note that this also accepts other profiles if they are supplied via the `ENV['AWS_PROFILE']` environment variable.

### Using IAM instance role

If your instance has an IAM role, then the credentials can be automatically resolved by the cookbook using Amazon instance metadata API.

You can then omit the authentication properties `aws_secret_access_key` and `aws_access_key` when using the resource.

Of course, the instance role must have the required policies. Here is a sample policy for EBS volume management:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:AttachVolume",
        "ec2:CreateVolume",
        "ec2:ModifyInstanceAttribute",
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

### Assuming roles via STS and using MFA

The following is an example of how roles can be assumed using MFA. The following can also be used to assumes roles that do not require MFA, just ensure that the MFA arguments (`serial_number` and `token_code`) are omitted.

This assumes you have also stored the `cfn_role_arn`, and `mfa_serial` attributes as well, but there are plenty of ways these attributes can be supplied (they could be stored locally in the consuming cookbook, for example).

Note that MFA codes cannot be recycled, hence the importance of creating a single STS session and passing that to resources. If multiple roles need to be assumed using MFA, it is probably prudent that these be broken up into different recipes and `chef-client` runs.

```ruby
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

aws_cloudformation_stack 'kitchen-test-stack' do
  action :create
  template_source 'kitchen-test-stack.tpl'
  aws_access_key sts.access_key_id
  aws_secret_access_key sts.secret_access_key
  aws_session_token sts.session_token
end
```

When running the cookbook, ensure that an attribute JSON is passed that supplies the MFA code. Example using chef-zero:

```
echo '{ "aws": { "mfa_code": "123456" } }' > mfa.json && chef-client -z -o 'recipe[aws_test]' -j mfa.json
```

### Running outside of an AWS instance

`region` can be specified on each resource if the cookbook is being run outside of an AWS instance. This can prevent some kinds of failures that happen when resources try to detect region.

```ruby
aws_cloudformation_stack 'kitchen-test-stack' do
  action :create
  template_source 'kitchen-test-stack.tpl'
  region 'us-east-1'
end
```

## Resources

### aws_cloudformation_stack

Manage CloudFormation stacks.

#### Actions:

- `create`: Creates the stack, or updates it if it already exists.
- `delete`: Begins the deletion process for the stack.

#### Properties:

- `template_source`: Required - the location of the CloudFormation template file. The file should be stored in the `files` directory in the cookbook.
- `parameters`: An array of `parameter_key` and `parameter_value` pairs for parameters in the template. Follow the syntax in the example above.
- `disable_rollback`: Set this to `true` if you want stack rollback to be disabled if creation of the stack fails. Default: `false`
- `stack_policy_body`: Optionally define a stack policy to apply to the stack, mainly used in protecting stack resources after they are created. For more information, see [Prevent Updates to Stack Resources](http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/protect-stack-resources.html) in the CloudFormation user guide.
- `iam_capability`: Set to `true` to allow the CloudFormation template to create IAM resources. This is the equivalent of setting `CAPABILITY_IAM` When using the SDK or CLI. Default: `false`
- `named_iam_capability`: Set to `true` to allow the CloudFormation template to create IAM resources with custom names. This is the equivalent of setting `CAPABILITY_NAMED_IAM` When using the SDK or CLI. Default: `false`

#### Examples:

```ruby
aws_cloudformation_stack 'example-stack' do
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

### aws_cloudwatch

Use this resource to manage CloudWatch alarms.

#### Actions:

- `create` - Create or update CloudWatch alarms.
- `delete` - Delete CloudWatch alarms.
- `disable_action` - Disable action of the CloudWatch alarms.
- `enable_action` - Enable action of the CloudWatch alarms.

#### Properties:

- `aws_secret_access_key`, `aws_access_key` and optionally `aws_session_token` - required, unless using IAM roles for authentication.
- `alarm_name` - the alarm name. If none is given on assignment, will take the resource name.
- `alarm_description` - the description of alarm. Can be blank also.
- `actions_enabled` - true for enable action on OK, ALARM or Insufficient data. if true, any of ok_actions, alarm_actions or insufficient_data_actions must be specified.
- `ok_actions` - array of action if alarm state is OK. If specified actions_enabled must be true.
- `alarm_actions` - array of action if alarm state is ALARM. If specified actions_enabled must be true.
- `insufficient_data_actions` - array of action if alarm state is INSUFFICIENT_DATA. If specified actions_enabled must be true.
- `metric_name` - CloudWatch metric name of the alarm. eg - CPUUtilization.Required parameter.
- `namespace` - namespace of the alarm. eg - AWS/EC2, required parameter.
- `statistic` - statistic of the alarm. Value must be in any of SampleCount, Average, Sum, Minimum or Maximum. Required parameter.
- `extended_statistic` - extended_statistic of the alarm. Specify a value between p0.0 and p100\. Optional parameter.
- `dimensions` - dimensions for the metric associated with the alarm. Array of name and value.
- `period` - in seconds, over which the specified statistic is applied. Integer type and required parameter.
- `unit` - unit of measure for the statistic. Required parameter.
- `evaluation_periods` - number of periods over which data is compared to the specified threshold. Required parameter.
- `threshold` - value against which the specified statistic is compared. Can be float or integer type. Required parameter.
- `comparison_operator` - arithmetic operation to use when comparing the specified statistic and threshold. The specified statistic value is used as the first operand.

For more information about parameters, see [CloudWatch Identifiers](http://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CW_Support_For_AWS.html) in the Using CloudWatch guide.

#### Examples:

```ruby
aws_cloudwatch "kitchen_test_alarm" do
  period 21600
  evaluation_periods 2
  threshold 50.0
  comparison_operator "LessThanThreshold"
  metric_name "CPUUtilization"
  namespace "AWS/EC2"
  statistic "Maximum"
  dimensions [{"name" : "InstanceId", "value" : "i-xxxxxxx"}]
  action :create
end
```

### aws_dynamodb_table

Use this resource to create and delete DynamoDB tables. This includes the ability to add global secondary indexes to existing tables.

#### Actions:

- `create`: Creates the table. Will update the following if the table exists:
- `global_secondary_indexes`: Will remove non-existent indexes, add new ones, and update throughput for existing ones. All attributes need to be present in `attribute_definitions`. No effect if the resource is omitted.
- `stream_specification`: Will update as shown. No effect is the resource is omitted.
- `provisioned_throughput`: Will update as shown.
- `delete`: Deletes the index.

#### Properties:

- `attribute_definitions`: Required. Attributes to create for the table. Mainly this is used to specify attributes that are used in keys, as otherwise one can add any attribute they want to a DynamoDB table.
- `key_schema`: Required. Used to create the primary key for the table. Attributes need to be present in `attribute_definitions`.
- `local_secondary_indexes`: Used to create any local secondary indexes for the table. Attributes need to be present in `attribute_definitions`.
- `global_secondary_indexes`: Used to create any global secondary indexes. Can be done to an existing table. Attributes need to be present in
- `attribute_definitions`.
- `provisioned_throughput`: Define the throughput for this table.
- `stream_specification`: Specify if there should be a stream for this table.

Several of the attributes shown here take parameters as shown in the [AWS Ruby SDK Documentation](http://docs.aws.amazon.com/sdkforruby/api/Aws/DynamoDB/Client.html#create_table-instance_method). Also, the [AWS DynamoDB Documentation](http://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Introduction.html) may be of further help as well.

#### Examples:

```ruby
aws_dynamodb_table 'example-table' do
  action :create
  attribute_definitions [
    { attribute_name: 'Id', attribute_type: 'N' },
    { attribute_name: 'Foo', attribute_type: 'N' },
    { attribute_name: 'Bar', attribute_type: 'N' },
    { attribute_name: 'Baz', attribute_type: 'S' }
  ]
  key_schema [
    { attribute_name: 'Id', key_type: 'HASH' },
    { attribute_name: 'Foo', key_type: 'RANGE' }
  ]
  local_secondary_indexes [
    {
      index_name: 'BarIndex',
      key_schema: [
        {
          attribute_name: 'Id',
          key_type: 'HASH'
        },
        {
          attribute_name: 'Bar',
          key_type: 'RANGE'
        }
      ],
      projection: {
        projection_type: 'ALL'
      }
    }
  ]
  global_secondary_indexes [
    {
      index_name: 'BazIndex',
      key_schema: [{
        attribute_name: 'Baz',
        key_type: 'HASH'
      }],
      projection: {
        projection_type: 'ALL'
      },
      provisioned_throughput: {
        read_capacity_units: 1,
        write_capacity_units: 1
      }
    }
  ]
  provisioned_throughput ({
    read_capacity_units: 1,
    write_capacity_units: 1
  })
  stream_specification ({
    stream_enabled: true,
    stream_view_type: 'KEYS_ONLY'
  })
end
```

### aws_ebs_volume

The resource only handles manipulating the EBS volume, additional resources need to be created in the recipe to manage the attached volume as a filesystem or logical volume.

#### Actions:

- `create` - create a new volume.
- `attach` - attach the specified volume.
- `detach` - detach the specified volume.
- `delete` - delete the specified volume.
- `snapshot` - create a snapshot of the volume.
- `prune` - prune snapshots.

#### Properties:

- `aws_secret_access_key`, `aws_access_key` and optionally `aws_session_token` - required, unless using IAM roles for authentication.
- `size` - size of the volume in gigabytes.
- `snapshot_id` - snapshot to build EBS volume from.
- `most_recent_snapshot` - use the most recent snapshot when creating a volume from an existing volume (defaults to false)
- `availability_zone` - EC2 region, and is normally automatically detected.
- `device` - local block device to attach the volume to, e.g. `/dev/sdi` but no default value, required.
- `volume_id` - specify an ID to attach, cannot be used with action `:create` because AWS assigns new volume IDs
- `timeout` - connection timeout for EC2 API.
- `snapshots_to_keep` - used with action `:prune` for number of snapshots to maintain.
- `description` - used to set the description of an EBS snapshot
- `volume_type` - "standard", "io1", or "gp2" ("standard" is magnetic, "io1" is provisioned SSD, "gp2" is general purpose SSD)
- `piops` - number of Provisioned IOPS to provision, must be >= 100
- `existing_raid` - whether or not to assume the raid was previously assembled on existing volumes (default no)
- `encrypted` - specify if the EBS should be encrypted
- `kms_key_id` - the full ARN of the AWS Key Management Service (AWS KMS) master key to use when creating the encrypted volume (defaults to master key if not specified)
- `delete_on_termination` - Boolean value to control whether or not the volume should be deleted when the instance it's attached to is terminated (defaults to nil). Only applies to `:attach` action.
- `tags` - Hash value to tag the new volumes or snapshots. Only applies to `:create` and `:snapshot` actions.

#### Examples:

Create a 50G volume, attach it to the instance as `/dev/sdi`:

```ruby
aws_ebs_volume 'db_ebs_volume' do
  size 50
  device '/dev/sdi'
  action [:create, :attach]
end
```

Create a new 50G volume from the snapshot ID provided and attach it as `/dev/sdi`.

```ruby
aws_ebs_volume 'db_ebs_volume_from_snapshot' do
  size 50
  device '/dev/sdi'
  snapshot_id 'snap-ABCDEFGH'
  action [:create, :attach]
end
```

### aws_elastic_ip

The `elastic_ip` resource provider does not support allocating new IPs. This must be done before running a recipe that uses the resource. After allocating a new Elastic IP, we recommend storing it in a databag and loading the item in the recipe.

#### Actions:

- `associate` - Associate an allocated IP to the node
- `disassociate` - Disassociate an allocated IP from the node

#### Properties:

- `aws_secret_access_key`, `aws_access_key` and optionally `aws_session_token` - required, unless using IAM roles for authentication.
- `ip`: String. The IP address to associate or disassociate.
- `timeout`: Integer. Default: 180\. Time in seconds to wait. 0 for unlimited.

#### Examples:

```ruby
aws_elastic_ip '34.15.30.10' do
  action :associate
end

aws_elastic_ip 'Server public IP' do
  ip '34.15.30.11'
  action :associate
end
```

### aws_elastic_lb

`elastic_lb` handles registering and removing nodes from ELBs. The resource also adds basic support for creating and deleting ELBs. Note that currently this resource is not fully idempotent so it will not update the existing configuration of an ELB.

#### Actions:

- `register` - Add a node to the ELB
- `deregister` - Remove a node from the ELB
- `create` - Create a new ELB
- `delete` - Delete an existing ELB

#### Properties:

- `aws_secret_access_key`, `aws_access_key` and optionally `aws_session_token` - required, unless using IAM roles for authentication.
- `name` - the name of the ELB, required.
- `region`, The region of the ELB. Defaults to the region of the node.
- `listeners`, Array or hashes. The ports/protocols the ELB will listen on. See the example for a sample.
- `security_groups`, Array. Security groups to apply to the ELB. Only needed when creating ELBs.
- `subnets`, Array. The subnets the ELB will listen in. Only needed when creating ELBs and when using VPCs.
- `availability_zones`: Array. The availability zones the ELB will listen in. Only needed when creating ELBs and when using classic networking.
- `tags`: Array.
- `scheme`: Array.

#### Examples

ELB running in classic networking listening on port 80.

```ruby
aws_elastic_lb 'Setup the ELB' do
  name 'example-elb'
  action :create
  availability_zones ['us-west-2a']
  listeners [
    {
      instance_port: 80,
      instance_protocol: 'HTTP',
      load_balancer_port: 80,
      protocol: 'HTTP',
    },
  ]
end
```

To register the node in the 'QA' ELB:

```ruby
aws_elastic_lb 'elb_qa' do
  name 'QA'
  action :register
end
```

### aws_iam_user

Use this resource to manage IAM users.

#### Actions:

- `create`: Creates the user. No effect if the user already exists.
- `delete`: Gracefully deletes the user (detaches from all attached entities, and deletes the user).

#### Properties

The IAM user takes the name of the resource. A `path` can be specified as well. For more information about paths, see [IAM Identifiers](http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/protect-stack-resources.html) in the Using IAM guide.

#### Examples:

```ruby
aws_iam_user 'example-user' do
  action :create
  path '/'
end
```

### aws_iam_group

Use this resource to manage IAM groups. The group takes the name of the resource.

#### Actions:

- `create`: Creates the group, and updates members and attached policies if the group already exists.
- `delete`: Gracefully deletes the group (detaches from all attached entities, and deletes the group).

#### Properties:

- `path`: A path can be supplied for the group. For information on paths, see [IAM Identifiers](http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/protect-stack-resources.html) in the Using IAM guide.
- `members`: An array of IAM users that are a member of this group.
- `remove_members`: Set to `false` to ensure that members are not removed from the group when they are not present in the defined resource. Default: `true`
- `policy_members`: An array of ARNs of IAM managed policies to attach to this resource. Accepts both user-defined and AWS-defined policy ARNs.
- `remove_policy_members`: Set to `false` to ensure that policies are not detached from the group when they are not present in the defined resource. Default: `true`

#### Examples:

```ruby
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

### aws_iam_policy

Use this resource to create an IAM policy. The policy takes the name of the resource.

#### Actions:

- `create`: Creates or updates the policy.
- `delete`: Gracefully deletes the policy (detaches from all attached entities, deletes all non-default policy versions, then deletes the policy).

#### Properties:

- `path`: A path can be supplied for the group. For information on paths, see [IAM Identifiers](http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/protect-stack-resources.html) in the Using IAM guide.
- `policy_document`: The JSON document for the policy.
- `account_id`: The AWS account ID that the policy is going in. Required if using non-user credentials (ie: IAM role through STS or instance role).

#### Examples:

```ruby
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

### aws_iam_role

Use this resource to create an IAM role. The policy takes the name of the resource.

#### Actions:

- `create`: Creates the role if it does not exist. If the role exists, updates attached policies and the `assume_role_policy_document`.
- `delete`: Gracefully deletes the role (detaches from all attached entities, and deletes the role).

#### Properties:

- `path`: A path can be supplied for the group. For information on paths, see [IAM Identifiers](http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/protect-stack-resources.html) in the Using IAM guide.
- `policy_members`: An array of ARNs of IAM managed policies to attach to this resource. Accepts both user-defined and AWS-defined policy ARNs.
- `remove_policy_members`: Set to `false` to ensure that policies are not detached from the group when they are not present in the defined resource. Default: `true`
- `assume_role_policy_document`: The JSON policy document to apply to this role for trust relationships. Dictates what entities can assume this role.

#### Examples:

```ruby
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

### aws_instance_monitoring

Allows detailed CloudWatch monitoring to be enabled for the current instance.

#### Actions:

- `enable` - Enable detailed CloudWatch monitoring for this instance (Default).
- `disable` - Disable detailed CloudWatch monitoring for this instance.

#### Properties:

- `aws_secret_access_key`, `aws_access_key` and optionally `aws_session_token` - required, unless using IAM roles for authentication.
- `region` - The AWS region containing the instance. Default: The current region of the node when running in AWS or us-east-1 if the node is not in AWS.

#### Examples:

```ruby
aws_instance_monitoring "enable detailed monitoring"
```

### aws_instance_role

Used to associate an IAM role (by way of an IAM instance profile) with an instance. Replaces the instance's current role association if one already exists.

#### Actions:

- `associate` - Associate role with the instance (Default).

#### Properties:

- `aws_secret_access_key`, `aws_access_key` and optionally `aws_session_token` - required, unless using IAM roles for authentication.
- `region` - The AWS region containing the instance. Default: The current region of the node when running in AWS or us-east-1 if the node is not in AWS.
- `instance_id` - The id of the instance to modify. Default: The current instance.
- `profile_arn` - The IAM instance profile to associate with the instance

#### Requirements

IAM permisions:
 * `ec2:DescribeIamInstanceProfileAssociations`
 * `ec2:AssociateIamInstanceProfile`
   * Only needed if the instance is not already associated with an IAM role
 * `ec2:ReplaceIamInstanceProfileAssociation`
   * Only needed if the instance is already associated with an IAM role
 * `iam:PassRole`
   * This can be restricted to the resource of the IAM role being associated

#### Examples:

```ruby
aws_instance_role "change to example role" do
  profile_arn 'arn:aws:iam::123456789012:instance-profile/ExampleInstanceProfile'
end
```

### aws_instance_term_protection

Allows termination protection (AKA `DisableApiTermination`) to be enabled for an instance.

#### Actions:

- `enable` - Enable termination protection for this instance (Default).
- `disable` - Disable termination protection for this instance.

#### Properties:

- `aws_secret_access_key`, `aws_access_key` and optionally `aws_session_token` - required, unless using IAM roles for authentication.
- `region` - The AWS region containing the instance. Default: The current region of the node when running in AWS or us-east-1 if the node is not in AWS.
- `instance_id` - The id of the instance to modify. Default: The current instance.

#### Examples:

```ruby
aws_instance_term_protection "enable termination protection"
```

### aws_kinesis_stream

Use this resource to create and delete Kinesis streams. Note that this resource cannot be used to modify the shard count as shard splitting is a somewhat complex operation (for example, even CloudFormation replaces streams upon update).

#### Actions:

- `create`: Creates the stream. No effect if the stream already exists.
- `delete`: Deletes the stream.

#### Properties:

- `starting_shard_count`: The number of shards the stream starts with

#### Examples:

```ruby
aws_kinesis_stream 'example-stream' do
 action :create
 starting_shard_count 1
end
```

### aws_resource_tag

`resource_tag` can be used to manipulate the tags assigned to one or more AWS resources, i.e. ec2 instances, EBS volumes or EBS volume snapshots.

#### Actions:

- `add` - Add tags to a resource.
- `update` - Add or modify existing tags on a resource -- this is the default action.
- `remove` - Remove tags from a resource, but only if the specified values match the existing ones.
- `force_remove` - Remove tags from a resource, regardless of their values.

#### Properties:

- `aws_secret_access_key`, `aws_access_key` and optionally `aws_session_token` - required, unless using IAM roles for authentication.
- `tags` - a hash of key value pairs to be used as resource tags, (e.g. `{ "Name" => "foo", "Environment" => node.chef_environment }`,) required.
- `resource_id` - resources whose tags will be modified. The value may be a single ID as a string or multiple IDs in an array. If no `resource_id` is specified the name attribute will be used.

#### Examples:

Assigning tags to a node to reflect its role and environment:

```ruby
aws_resource_tag node['ec2']['instance_id'] do
  tags('Name' => 'www.example.com app server',
       'Environment' => node.chef_environment)
  action :update
end
```

Assigning a set of tags to multiple resources, e.g. ebs volumes in a disk set:

```ruby
aws_resource_tag 'my awesome raid set' do
  resource_id ['vol-d0518cb2', 'vol-fad31a9a', 'vol-fb106a9f', 'vol-74ed3b14']
  tags('Name' => 'My awesome RAID disk set',
       'Environment' => node.chef_environment)
end
```

```ruby
aws_resource_tag 'db_ebs_volume' do
  resource_id lazy { node['aws']['ebs_volume']['db_ebs_volume']['volume_id'] }
  tags ({ 'Service' => 'Frontend' })
end
```

### aws_route53_record

#### Actions:

- `create` - Create a Route53 record
- `delete` - Remove a Route53 record

#### Properties:

- `aws_secret_access_key`, `aws_access_key` and optionally `aws_session_token` - required, unless using IAM roles for authentication.
- `name` Required. String. - name of the domain or subdomain.
- `value` String Array - value appropriate to the `type`.. for type 'A' value would be an IP address in IPv4 format for example.
- `type` Required. String [DNS record type](http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/ResourceRecordTypes.html)
- `ttl` Integer default: 3600 - time to live, the amount of time in seconds to cache information about the record
- `weight` Optional. String. - a value that determines the proportion of DNS queries that will use this record for the response. Valid options are between 0-255\. NOT CURRENTLY IMPLEMENTED
- `set_identifier` Optional . String. - a value that uniquely identifies record in the group of weighted record sets
- `geo_location` String.
- `geo_location_country` String
- `geo_location_continent` String
- `geo_location_subdivision` String
- `zone_id` String
- `region` String
- `overwrite` [true, false] default: true
- `alias_target` Optional. Hash. - [Associated with Amazon 'alias' type records. The hash contents varies depending on the type of target the alias points to.](http://docs.aws.amazon.com/Route53/latest/APIReference/API_AliasTarget.html)
- `mock` [true, false] default: false
- `fail_on_error` [true, false] default: false

#### Examples:

Create a simple record

```ruby
route53_record "create a record" do
  name  "test"
  value "16.8.4.2"
  type  "A"
  weight "1"
  set_identifier "my-instance-id"
  zone_id "ID VALUE"
  overwrite true
  fail_on_error false
  action :create
end
```

Delete an existing record. Note that value is still necessary even though we're deleting. This is a limitation in the AWS SDK.

```ruby
aws_route53_record "delete a record" do
  name  "test"
  value "16.8.4.2"
  type 'A'
  value '123'
  action :delete
end
```

### aws_route53_zone

#### Actions:

- `create` - Create a Route53 zone
- `delete` - Remove a Route53 zone

#### Properties:

- `aws_secret_access_key`, `aws_access_key` and optionally `aws_session_token` - required, unless using IAM roles for authentication.
- `name` Required. String. - name of the zone.
- `description` String. - Description shown in the Route53 UI
- `private` [true, false]. default: false - Should this be a private zone for use in your VPCs or a Public zone
- `vpc_id` String. If creating a Private zone this is the VPC to associate the zone with.

#### Examples:

```ruby
aws_route53_zone 'testkitchen.dmz' do
  description 'My super important zone'
  action :create
end
```

### aws_secondary_ip.rb

This feature is available only to instances within VPCs. It allows you to assign multiple private IP addresses to a network interface.

#### Actions:

- `assign` - Assign a private IP to the instance.
- `unassign` - Unassign a private IP from the instance.

#### Properties:

- `aws_secret_access_key`, `aws_access_key` and optionally `aws_session_token` - required, unless using IAM roles for authentication.
- `ip` - the private IP address. - required.
- `interface` - the network interface to assign the IP to. If none is given, uses the default interface.
- `timeout` - connection timeout for EC2 API.

### aws_s3_file

`s3_file` can be used to download a file from s3 that requires aws authorization. This is a wrapper around the core chef `remote_file` resource and supports the same resource attributes as `remote_file`. See [remote_file Chef Docs] (<https://docs.chef.io/resource_remote_file.html>) for a complete list of available attributes.

#### Properties:

- `aws_secret_access_key`, `aws_access_key` and optionally `aws_session_token` - required, unless using IAM roles for authentication.
- `region` - The AWS region containing the file. Default: The current region of the node when running in AWS or us-east-1 if the node is not in AWS.

#### Actions:

- `create`: Downloads a file from s3
- `create_if_missing`: Downloads a file from S3 only if it doesn't exist locally
- `delete`: Deletes a local file
- `touch`: Touches a local file

#### Examples:

```ruby
aws_s3_file '/tmp/foo' do
  bucket 'i_haz_an_s3_buckit'
  remote_path 'path/in/s3/bukket/to/foo'
  region 'us-west-1'
end
```

```ruby
aws_s3_file '/tmp/bar' do
  bucket 'i_haz_another_s3_buckit'
  remote_path 'path/in/s3/buckit/to/foo'
  region 'us-east-1'
  requester_pays true
end
```

### aws_s3_bucket

`s3_bucket` can be used to create or delete S3 buckets. Note that buckets can only be deleted if they are empty unless you specify `delete_all_objects` true, which will delete EVERYTHING in your bucket first.

#### Actions:

- `create`: Creates the bucket
- `delete`: Deletes the bucket

#### Properties:

- `aws_secret_access_key`, `aws_access_key` and optionally `aws_session_token` - required, unless using IAM roles for authentication.
- `region` - The AWS region containing the bucket. Default: The current region of the node when running in AWS or us-east-1 if the node is not in AWS.
- `versioning` - Enable or disable S3 bucket versioning. Default: false
- `delete_all_objects` - Used with the `:delete` action to delete all objects before deleting a bucket. Use with EXTREME CAUTION. default: false (for a reason)

#### Examples:

```ruby
aws_s3_bucket 'some-unique-name' do
  aws_access_key aws['aws_access_key_id']
  aws_secret_access_key aws['aws_secret_access_key']
  versioning true
  region 'us-west-1'
  action :create
end
```

```ruby
aws_s3_bucket 'another-unique-name' do
  aws_access_key aws['aws_access_key_id']
  aws_secret_access_key aws['aws_secret_access_key']
  region 'us-west-1'
  action :delete
end
```

### aws_secondary_ip

The `secondary_ip` resource provider allows one to assign/un-assign multiple private secondary IPs on an instance within a VPC. The number of secondary IP addresses that you can assign to an instance varies by instance type. If no ip address is provided on assign, a random one from within the subnet will be assigned. If no interface is provided, the default interface as determined by Ohai will be used.

#### Examples:

```ruby
aws_secondary_ip 'assign_additional_ip' do
  aws_access_key aws['aws_access_key_id']
  aws_secret_access_key aws['aws_secret_access_key']
  ip ip_info['private_ip']
  interface 'eth0'
  action :assign
end
```

### aws_ssm_parameter_store

The 'ssm_parameter_store' resource provider allows one to get, create and delete keys and values in the AWS Systems Manager Parameter Store.  Values can be stored as plain text or as an encrypted string.  In order to use the paramater store resource your ec2 instance role must have the proper policy.  This sample policy allows get, creating and deleting parameters. You can adjust the policy to your needs.  It is recommended that you have one role with the ability to create secrets and another that can only read the secrets.
```ruby
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "ssm:PutParameter",
                "ssm:DeleteParameter",
                "ssm:RemoveTagsFromResource",
                "ssm:GetParameterHistory",
                "ssm:AddTagsToResource",
                "ssm:GetParametersByPath",
                "ssm:GetParameters",
                "ssm:GetParameter",
                "ssm:DeleteParameters"
            ],
            "Resource": [
                "arn:aws:ssm:*:*:document/*",
                "arn:aws:ssm:*:*:parameter/*"
            ]
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": "ssm:DescribeParameters",
            "Resource": "*"
        }
    ]
}
```
#### Actions:

- `get` - Retrieve a key/value from the AWS Systems Manager Parameter Store.
- `create` - Create a key/value in the AWS Systems Manager Parameter Store.
- `delete` - Remove the key/value from the AWS Systems Manager Parameter Store.

#### Properties:

- `aws_secret_access_key`, `aws_access_key` and optionally `aws_session_token` - required, unless using IAM roles for authentication.
- `name` - Identifies the parameters (get, create, delete, required)
- `description` - Type a description to help identify parameters and their intended use. (create, optional)
- `value` - Item stored in AWS Systems Manager Parameter Store (create, required)
- `type` - Describes the value that is stored.  Can be a String, StringList or SecureString (create, required)
- `key_id` - The value after key/ in the ARN of the KSM key which is used with a SecureString.  If SecureString is chosen and no key_id is specified AWS Systems Manager Parameter Store uses the default AWS KMS key assigned to your AWS account (create, optional)
- `overwrite` - Indicates if create should overwrite an existing parameters with a new value.  AWS Systems Manager Parameter Store versions new values (create, optional defaults to true)
- `with_decryption` - Indicates if AWS Systems Manager Parameter Store should decrypt the value.  Note that it must have access to the encryption key for this to succeed (get, optional, defaults to false)
- `allowed_pattern` - A regular expression used to validate the parameter value (create, optional)

#### Examples
##### Create String Parameter
```ruby
aws_ssm_parameter_store 'create testkitchen record' do
  name 'testkitchen'
  description 'testkitchen'
  value 'testkitchen'
  type 'String'
  action :create
  aws_access_key node['aws_test']['key_id']
  aws_secret_access_key node['aws_test']['access_key']
end
```
##### Create Encrypted String Parameter with Custom KMS Key
```ruby
aws_ssm_parameter_store "create encrypted test kitchen record" do
  name '/testkitchen/EncryptedStringCustomKey'
  description 'Test Kitchen Encrypted Parameter - Custom'
  value 'Encrypted Test Kitchen Custom'
  type 'SecureString'
  key_id '5d888999-5fca-3c71-9929-014a529236e1'
  action :create
  aws_access_key node['aws_test']['key_id']
  aws_secret_access_key node['aws_test']['access_key']
 end
```
##### Delete Parameter
```ruby
aws_ssm_parameter_store 'delete testkitchen record' do
  name 'testkitchen'
  aws_access_key node['aws_test']['key_id']
  aws_secret_access_key node['aws_test']['access_key']
  action :delete
end
```
##### Get Parameters and Populate Template
```ruby
aws_ssm_parameter_store 'get clear_value' do
  name '/testkitchen/ClearTextString'
  return_key 'clear_value'
  action :get
  aws_access_key node['aws_test']['key_id']
  aws_secret_access_key node['aws_test']['access_key']
end

aws_ssm_parameter_store 'get decrypted_value' do
  name '/testkitchen/EncryptedStringDefaultKey'
  return_key 'decrypted_value'
  with_decryption true
  action :get
  aws_access_key node['aws_test']['key_id']
  aws_secret_access_key node['aws_test']['access_key']
end

aws_ssm_parameter_store 'get decrypted_custom_value' do
  name '/testkitchen/EncryptedStringCustomKey'
  return_key 'decrypted_custom_value'
  with_decryption true
  action :get
  aws_access_key node['aws_test']['key_id']
  aws_secret_access_key node['aws_test']['access_key']
end

template '/tmp/file_with_data.txt' do
  source 'file_with_data.txt.erb'
  owner 'ec2-user'
  group 'ec2-user'
  mode '0755'
  sensitive true
  variables lazy {
    {
       clear_value: node.run_state['clear_value'],
       decrypted_custom_value: node.run_state['decrypted_custom_value'],
       decrypted_value: node.run_state['decrypted_value'],
    }
  }
end
```
###### Template (file_with_data.txt.erb)
```ruby
ClearValue="<%= @clear_value %>"
DecryptedCustomValue="<%= @decrypted_custom_value %>"
DecryptedValue="<%= @decrypted_value %>"
```
##### Get bucket name and retrieve file
```ruby
aws_ssm_parameter_store 'get bucketname' do
  name 'bucketname'
  return_key 'bucketname'
  action :get
  aws_access_key node['aws_test']['key_id']
  aws_secret_access_key node['aws_test']['access_key']
end

aws_s3_file "/tmp/test.txt" do
  bucket lazy {node.run_state['bucketname']}
  remote_path "test.txt"
  aws_access_key_id node[:custom_access_key]
  aws_secret_access_key node[:custom_secret_key]
end
```
## License and Authors

- Author:: Chris Walters ([cw@chef.io](mailto:cw@chef.io))
- Author:: AJ Christensen ([aj@chef.io](mailto:aj@chef.io))
- Author:: Justin Huff ([jjhuff@mspin.net](mailto:jjhuff@mspin.net))

Copyright 2009-2016, Chef Software, Inc.

```
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
