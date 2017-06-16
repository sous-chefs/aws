property :description, String
property :private, [true, false], default: false
property :vpc_id, String

# authentication
property :aws_access_key,        String
property :aws_secret_access_key, String
property :aws_session_token,     String
property :aws_assume_role_arn,   String
property :aws_role_session_name, String
property :region,                String, default: lazy { fallback_region }

include AwsCookbook::Ec2 # needed for aws_region helper

action :create do
  if zone_exists?(zone_name)
    Chef::Log.debug("#{zone_name} already exists. Nothing to create.")
  else
    converge_by("create zone #{zone_name}") do
      route53_client.create_hosted_zone(create_data_structure)
    end
  end
end

action :delete do
  if zone_exists?(zone_name)
    zone_id = zone_id_from_name(zone_name)
    converge_by("delete zone #{zone_name} (#{zone_id})") do
      route53_client.delete_hosted_zone(id: zone_id)
    end
  else
    Chef::Log.debug("#{zone_name} does not exist. Nothing to delete.")
  end
end

action_class do
  include AwsCookbook::Ec2

  # convert the passed name to the trailing period format
  def zone_name
    @name ||= new_resource.name[-1] == '.' ? new_resource.name : "#{new_resource.name}."
  end

  # find the zone ID by zone name
  def zone_id_from_name(name)
    route53_client.list_hosted_zones_by_name(dns_name: name).hosted_zones.collect { |x| x.id if x.name == name }.first
  end

  # see if the zone exists in the aws account.
  # we're passing the name and then selecting on it because we want
  # a small response from AWS, but if the name isn't found AWS returns
  # everything so we have to find it ourselves
  def zone_exists?(name)
    route53_client.list_hosted_zones_by_name(dns_name: name).hosted_zones.select { |r| r.name == name }.any?
  end

  def create_data_structure
    require 'time'
    # standard zone values assuming we're not private
    request_data = {
      name: zone_name,
      hosted_zone_config: {
        comment: new_resource.description,
        private_zone: false,
      },
      caller_reference: Time.now.to_s,
    }

    # add private values if we're private
    if new_resource.private
      request_data['hosted_zone_config']['private_zone'] = true
      request_data['vpc'] = { vpc_id: new_resource.vpc_id }
    end

    request_data
  end

  def route53_client
    @route53 ||= begin
      require 'aws-sdk'
      Chef::Log.debug('Initializing Aws::Route53::Client')
      create_aws_interface(::Aws::Route53::Client, region: new_resource.region)
    end
  end
end
