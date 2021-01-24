#
# Cookbook:: aws
# Resource:: security_group
#
# Technically managing the security group and the ingress/egress
# rules are unique API calls. It's much easier to handle them in
# a single provider, partially to limit the number of API calls.
# Mostly because describing a security group returns the entire object
# which we can use to compare against our object

resource_name :aws_security_group
provides :aws_security_group

provides :security_group # legacy name

# => Define the Resource Properties
property :security_group_name, String, name_property: true
property :description, String, default: 'created by chef'
property :vpc_id, String, required: true

# Ingress/Egress rules
property :ip_permissions, Array, default: []
# Even though `ip_permissions` matches the aws def
# The alias of _ingress makes it more explicit considering
# there is an _egress
alias :ip_permissions_ingress :ip_permissions
property :ip_permissions_egress, Array, default: []

# Tags
property :tags, Array, default: []

# => AWS Config
property :aws_access_key, String
property :aws_secret_access_key, String, sensitive: true
property :aws_session_token, String, sensitive: true
property :aws_assume_role_arn, String
property :aws_role_session_name, String
property :region, String, default: lazy { fallback_region }

include AwsCookbook::Ec2 # needed for aws_region helper
include AwsCookbook::SecurityGroup # ip_permissions helpers

action :create do
  security_group_name = new_resource.security_group_name
  existing_security_group = action_class_describe_security_groups(new_resource.vpc_id, security_group_name)
  if existing_security_group.nil?
    converge_by("create security group #{security_group_name}") do
      Chef::Log.info("creating security group #{security_group_name}")
      # https://docs.aws.amazon.com/sdkforruby/api/Aws/EC2/Client.html#create_security_group-instance_method
      response = action_class_create_security_group(security_group_name, new_resource.description, new_resource.vpc_id)
      group_id = response.group_id
      Chef::Log.info "Created group_id: #{group_id}"
      # Reload
      existing_security_group = action_class_wait_until_ready(new_resource.vpc_id, security_group_name)
    end
  else
    Chef::Log.debug("security group #{existing_security_group} already exists")
  end

  group_id = existing_security_group.group_id

  # Tags
  chef_tags = new_resource.tags.map(&:to_h)
  aws_tags = existing_security_group.tags.map(&:to_h)
  aws_tags_not_in_chef = aws_tags - chef_tags
  unless aws_tags_not_in_chef.empty?
    converge_by("removing security group tags for #{security_group_name}") do
      Chef::Log.info "removing tags #{aws_tags_not_in_chef}"
      action_class_delete_tags(group_id, aws_tags_not_in_chef)
    end
  end
  chef_tags_not_in_aws = chef_tags - aws_tags
  unless chef_tags_not_in_aws.empty?
    converge_by("adding security group tags for #{security_group_name}") do
      Chef::Log.info "adding tags #{chef_tags_not_in_aws}"
      action_class_create_tags(group_id, chef_tags_not_in_aws)
    end
  end

  # Ingress
  chef_ingress = AwsCookbook::SecurityGroup.normalize_hash_ip_permissions(new_resource.ip_permissions)
  aws_ingress = AwsCookbook::SecurityGroup.normalize_aws_types_ip_permissions(existing_security_group['ip_permissions'])
  aws_ingress_rules_not_in_chef = aws_ingress - chef_ingress
  unless aws_ingress_rules_not_in_chef.empty?
    converge_by("removing security group ingress rules for #{security_group_name}") do
      Chef::Log.info "removing  ingress #{aws_ingress_rules_not_in_chef}"
      action_class_delete_security_group_ingress(group_id, aws_ingress_rules_not_in_chef)
    end
  end
  chef_ingress_rules_not_in_aws = chef_ingress - aws_ingress
  unless chef_ingress_rules_not_in_aws.empty?
    converge_by("adding security group ingress rules for #{security_group_name}") do
      Chef::Log.info "adding ingress #{chef_ingress_rules_not_in_aws}"
      action_class_create_security_group_ingress(group_id, chef_ingress_rules_not_in_aws)
    end
  end

  # Egress
  chef_egress = AwsCookbook::SecurityGroup.normalize_hash_ip_permissions(new_resource.ip_permissions_egress)
  aws_egress = AwsCookbook::SecurityGroup.normalize_aws_types_ip_permissions(existing_security_group['ip_permissions_egress'])
  aws_egress_rules_not_in_chef = aws_egress - chef_egress
  unless aws_egress_rules_not_in_chef.empty?
    converge_by("removing security group egress rules for #{security_group_name}") do
      Chef::Log.info "removing egress #{aws_egress_rules_not_in_chef}"
      action_class_delete_security_group_egress(group_id, aws_egress_rules_not_in_chef)
    end
  end
  chef_egress_rules_not_in_aws = chef_egress - aws_egress
  unless chef_egress_rules_not_in_aws.empty?
    converge_by("adding security group egress rules for #{security_group_name}") do
      Chef::Log.info "adding egress #{chef_egress_rules_not_in_aws}"
      action_class_create_security_group_egress(group_id, chef_egress_rules_not_in_aws)
    end
  end
end

action_class do
  include AwsCookbook::Ec2

  # Creates sg tags
  # https://docs.aws.amazon.com/sdkforruby/api/Aws/EC2/Client.html#create_tags-instance_method
  # @param group_id[String]
  # @param tags [Array<Types::Tag>]
  def action_class_create_tags(group_id, tags)
    ec2.create_tags(
      resources: [
        group_id,
      ],
      tags: tags
    )
  end

  # Deletes sg tags
  # https://docs.aws.amazon.com/sdkforruby/api/Aws/EC2/Client.html#delete_tags-instance_method
  # @param group_id[String]
  # @param tags [Array<Types::Tag>]
  def action_class_delete_tags(group_id, tags)
    ec2.delete_tags(
      resources: [
        group_id,
      ],
      tags: tags
    )
  end

  # Waits for a security group to exist, returning the group
  # This is a hack until -> https://github.com/aws/aws-sdk-ruby/pull/1992
  # @param vpc_id [String]
  # @param security_group_name [String]
  def action_class_wait_until_ready(vpc_id, security_group_name)
    sleep(5)
    begin
      retries ||= 0
      sg = action_class_describe_security_groups(vpc_id, security_group_name)
      raise "#{security_group_name} does not yet exist..." if sg.nil?
    rescue StandardError
      sleep(5)
      retry if (retries += 1) < 5
    end
    sg
  end

  # Creates a security group
  # See the below documentation for parameter details
  # https://docs.aws.amazon.com/sdkforruby/api/Aws/EC2/Client.html#create_security_group-instance_method
  # @param name [String]
  # @param description [String]
  # @param vpc_id [String]
  def action_class_create_security_group(name, description, vpc_id)
    ec2.create_security_group(
      description: description,
      group_name: name,
      vpc_id: vpc_id
    )
  end

  # Creates a security group ingress rule
  # See the below documentation for parameter details
  # https://docs.aws.amazon.com/sdkforruby/api/Aws/EC2/Client.html#authorize_security_group_ingress-instance_method
  # @param group_id [String]
  # @param ip_permissions [Array<Types::IpPermission>]
  def action_class_create_security_group_ingress(group_id, ip_permissions)
    ec2.authorize_security_group_ingress(
      group_id: group_id,
      ip_permissions: ip_permissions
    )
  end

  # Deletes a security group ingress rule
  # See the below documentation for parameter details
  # https://docs.aws.amazon.com/sdkforruby/api/Aws/EC2/Client.html#revoke_security_group_ingress-instance_method
  # @param group_id [String]
  # @param ip_permissions [Array<Types::IpPermission>]
  def action_class_delete_security_group_ingress(group_id, ip_permissions)
    ec2.revoke_security_group_ingress(
      group_id: group_id,
      ip_permissions: ip_permissions
    )
  end

  # Creates a security group egress rule
  # See the below documentation for parameter details
  # https://docs.aws.amazon.com/sdkforruby/api/Aws/EC2/Client.html#authorize_security_group_egress-instance_method
  # @param group_id [String]
  # @param ip_permissions [Array<Types::IpPermission>]
  def action_class_create_security_group_egress(group_id, ip_permissions)
    ec2.authorize_security_group_egress(
      group_id: group_id,
      ip_permissions: ip_permissions
    )
  end

  # Deletes a security group egress rule
  # See the below documentation for parameter details
  # https://docs.aws.amazon.com/sdkforruby/api/Aws/EC2/Client.html#revoke_security_group_egress-instance_method
  # @param group_id [String]
  # @param ip_permissions [Array<Types::IpPermission>]
  def action_class_delete_security_group_egress(group_id, ip_permissions)
    ec2.revoke_security_group_egress(
      group_id: group_id,
      ip_permissions: ip_permissions
    )
  end

  # Describes a security group, by name
  # See the below documentation for parameter details
  # http://docs.aws.amazon.com/sdkforruby/api/Aws/EC2/Client.html#describe_security_groups-instance_method
  # @param vpc_id [String]
  # @param security_group_name [String]
  def action_class_describe_security_groups(vpc_id, security_group_name)
    require 'aws-sdk-ec2'

    # Filter by vpc as the name may not be unique across vpcs
    filter_vpc = Aws::EC2::Types::Filter.new
    filter_vpc.name = 'vpc-id'
    filter_vpc.values = [vpc_id]

    # Use a group-name filter to avoid the exception:
    # "You may not reference Amazon VPC security groups by name."
    filter_name = Aws::EC2::Types::Filter.new
    filter_name.name = 'group-name'
    filter_name.values = [security_group_name]

    options = {}
    options[:filters] = [filter_vpc, filter_name]

    begin
      response = ec2.describe_security_groups(options)
    rescue Aws::EC2::Errors::InvalidGroupNotFound
      # This is OK - we'll create it if it doesn't exist
      return
    end

    # We only expect one security group to be returned
    if response.security_groups.empty?
      nil
    else
      response.security_groups[0]
    end
  end
end
