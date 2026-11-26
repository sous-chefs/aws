# aws_network_interface

Manages an EC2 Elastic Network Interface (ENI) for a secondary device on network card 0.

The resource identifies an ENI by its subnet and the exact value of the
`sous-chefs:aws-network-interface` tag. It sets that tag in the create request
using the Chef resource name. Choose a stable, unique name within the subnet.
Names can contain 1–256 ASCII letters, digits, dots, underscores, colons or hyphens.
Reserve this tag for the cookbook. Adding it to another ENI makes that interface
eligible for management. A lookup with multiple matches fails before mutation.

## Actions

| Action | Behaviour |
| --- | --- |
| `:create` | Creates and tags the ENI if absent, then waits for EC2 to report it as available. An existing match satisfies this action. |
| `:attach` | Attaches an available managed ENI to the specified instance and device. An existing attachment at that target satisfies the action. A different target causes an error. |
| `:detach` | Detaches the managed ENI only if the instance and device match. Waits for the ENI to become available. An absent or available ENI satisfies the action. |
| `:delete` | Deletes a detached, available managed ENI. An absent ENI satisfies the action. An attached ENI causes an error. |

`:create` is the default action. Use `[:create, :attach]` to provision and
`[:detach, :delete]` to remove an ENI. Readiness checks poll up to 15 times at
two-second intervals. If a call fails or a wait times out, EC2 may still be
processing the request. Allow it to settle before converging again. The pinned
EC2 SDK predates the create client token. Run converges for the same account,
region, subnet and name serially to avoid duplicate creation.

## Properties

| Property | Purpose |
| --- | --- |
| `subnet_id` | Required for all actions. The subnet scopes the identity and determines where the ENI is created. |
| `instance_id` | Required for attach and detach. The EC2 instance targeted by the action. |
| `device_index` | Required for attach and detach. A positive device index on network card 0. |
| `description` | Optional ENI description at creation. |
| `private_ip_address` | Optional primary private IPv4 address at creation. EC2 assigns an address when omitted. |
| `security_groups` | Optional array of security group IDs at creation. EC2 uses the VPC default when omitted. |

The resource uses the cookbook's common AWS region and credential properties.
Creation properties apply when provisioning an ENI. Editing them has no effect
on an existing ENI. The resource manages the EC2 interface and its attachment.
Guest OS network configuration is handled separately.

The AWS principal needs `ec2:DescribeNetworkInterfaces` and permission for the
requested actions (`ec2:CreateNetworkInterface`, `ec2:AttachNetworkInterface`,
`ec2:DetachNetworkInterface`, `ec2:DeleteNetworkInterface`). Creation also
requires `ec2:CreateTags` for tagging on create.

## Example

```ruby
aws_network_interface 'app-secondary' do
  region 'eu-west-2'
  subnet_id 'subnet-0123456789abcdef0'
  instance_id 'i-0123456789abcdef0'
  device_index 1
  security_groups ['sg-0123456789abcdef0']
  action [:create, :attach]
end
```

The original ENI implementation was contributed by [eherot](https://github.com/eherot)
and submitted by [jeffbyrnes](https://github.com/jeffbyrnes) in
[network_interfaces PR #32](https://github.com/sous-chefs/network_interfaces/pull/32).
