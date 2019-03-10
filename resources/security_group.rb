#
# Cookbook:: aws
# Resource:: security_group
#

resource_name :security_group
provides :aws_security_group

# => Define the Resource Properties
property :name, String, name_property: true
property :description, String
property :vpc_id, String, required: true

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
      Chef::Log.info "Created group_id: #{response.group_id}"
    end
  else
    Chef::Log.debug("security group #{existing_security_group} already exists")
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
