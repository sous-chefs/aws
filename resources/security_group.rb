#
# Cookbook:: aws
# Resource:: security_group
#
# Technically managing the security group and the ingress/egress
# rules are unique API calls.  It's much easier to handle them in
# a single provider, partially to limit the number of API calls.
# Mostly because describing a security group returns the entire object
# which we can use to compare against our object

resource_name :security_group
provides :aws_security_group

# => Define the Resource Properties
property :name, String, name_property: true
property :description, String
property :vpc_id, String, required: true

# Ingress/Egress rules
property :ip_permissions, Array, default: []
property :ip_permissions_egress, Array, default: []

# => AWS Config
property :aws_access_key, String
property :aws_secret_access_key, String
property :aws_session_token, String
property :aws_assume_role_arn, String
property :aws_role_session_name, String
property :region, String, default: lazy { fallback_region }

include AwsCookbook::Ec2 # needed for aws_region helper

action :create do
  existing_security_group = action_class_describe_security_groups(new_resource.name)
  if existing_security_group.nil?
    converge_by("create security group #{new_resource.name}") do
      Chef::Log.info("creating security group #{new_resource.name}")
      # https://docs.aws.amazon.com/sdkforruby/api/Aws/EC2/Client.html#create_security_group-instance_method
      response = action_class_create_security_group(new_resource.name, new_resource.description, new_resource.vpc_id)
      group_id = response.group_id
      Chef::Log.info "Created group_id: #{group_id}"
      # Reload
      existing_security_group.reload.data
    end
  else
    group_id = existing_security_group.group_id
    Chef::Log.debug("security group #{existing_security_group} already exists")
  end

  # TODO: Manage Tags

  # Convert the chef array of hashes for ip_permissions to an actual AWS data structure
  # This will be beneficial since it will:
  # Automatically order/sort all keys
  # Initialize default values
  # Protect against compatibility problems if this class is ever updated
  chef_ingress = new_resource.ip_permissions.map { |i| Aws::EC2::Types::IpPermission.new(i).to_h }
  aws_ingress = existing_security_group['ip_permissions'].map(&:to_h)
  aws_ingress_rules_not_in_chef = aws_ingress - chef_ingress
  unless aws_ingress_rules_not_in_chef.empty?
    converge_by("removing security group ingress rules for #{new_resource.name}") do
      Chef::Log.info "removing #{aws_ingress_rules_not_in_chef}"
      action_class_delete_security_group_ingress(group_id, aws_ingress_rules_not_in_chef)
    end
  end
  chef_ingress_rules_not_in_aws = chef_ingress - aws_ingress
  unless chef_ingress_rules_not_in_aws.empty?
    converge_by("adding security group ingress rules for #{new_resource.name}") do
      Chef::Log.info "adding #{chef_ingress_rules_not_in_aws}"
      action_class_create_security_group_ingress(group_id, chef_ingress_rules_not_in_aws)
    end
  end

  chef_egress = new_resource.ip_permissions_egress.map { |i| Aws::EC2::Types::IpPermission.new(i).to_h }
  aws_egress = existing_security_group['ip_permissions_egress'].map(&:to_h)
  aws_egress_rules_not_in_chef = aws_egress - chef_egress
  unless aws_egress_rules_not_in_chef.empty?
    converge_by("removing security group egress rules for #{new_resource.name}") do
      Chef::Log.info "removing #{aws_egress_rules_not_in_chef}"
      action_class_delete_security_group_egress(group_id, aws_egress_rules_not_in_chef)
    end
  end
  chef_egress_rules_not_in_aws = chef_egress - aws_egress
  unless chef_egress_rules_not_in_aws.empty?
    converge_by("adding security group egress rules for #{new_resource.name}") do
      Chef::Log.info "adding #{chef_egress_rules_not_in_aws}"
      action_class_create_security_group_egress(group_id, chef_egress_rules_not_in_aws)
    end
  end
end

action_class do
  include AwsCookbook::Ec2

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
  # @param security_group_name [String]
  def action_class_describe_security_groups(security_group_name)
    group_names = [security_group_name]
    options = {}
    # options[:filters] = filters if filters.any?
    options[:group_names] = group_names if group_names.any?
    # options[:group_ids] = group_ids if group_ids.any?
    options[:max_results] = 1

    response = ec2.describe_security_groups(options)

    # We only expect one security group to be returned
    if response.security_groups.empty?
      nil
    else
      response.security_groups[0]
    end
  end
end
