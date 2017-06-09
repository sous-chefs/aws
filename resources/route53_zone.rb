property :name, String, required: true, name_property: true
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
  unless zone_exists?(zone_name)
    converge_by("create zone #{zone_name}") do
      require 'time'
      # standard zone values assuming we're not private
      request_data = {
        name: zone_name,
        hosted_zone_config: {
          comment: new_resource.description,
          private_zone: false,
        },
        caller_reference: Time.now.to_s
      }

      # add private values if we're private
      if new_resource.private
        request_data['hosted_zone_config']['private_zone'] = true
        request_data['vpc'] = { vpc_id: new_resource.vpc_id }
      end

      route53_client.create_hosted_zone(request_data)
    end
  end
end

action :delete do
end

action_class do
  include AwsCookbook::Ec2

  # convert the passed name to the trailing period format
  def zone_name
    @name ||= new_resource.name[-1] == '.' ? new_resource.name : "#{new_resource.name}."
  end

  # see if the zone exists in the aws account.
  # we're passing the name and then selecting on it because we want
  # a small response from AWS, but if the name isn't found AWS returns
  # everything so we have to find it ourselves
  def zone_exists?(name)
    route53_client.list_hosted_zones_by_name(dns_name: name).hosted_zones.select { |r| r.name == name }.any?
  end

  def route53_client
    @route53 ||= begin
      require 'aws-sdk'
      Chef::Log.debug('Initializing Aws::Route53::Client')
      create_aws_interface(::Aws::Route53::Client, region: new_resource.region)
    end
  end
end
