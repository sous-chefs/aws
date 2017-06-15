property :resource_id,           [String, Array], regex: /(i|snap|vol)-[a-fA-F0-9]{8}/, name_property: true
property :tags,                  Hash, required: true

# authentication
property :aws_access_key,        String
property :aws_secret_access_key, String
property :aws_session_token,     String
property :aws_assume_role_arn,   String
property :aws_role_session_name, String
property :region,                String, default: lazy { fallback_region }

include AwsCookbook::Ec2 # needed for aws_region helper

action :update do
  Chef::Log.debug("The current tags on the node are #{current_tags}")

  updated_tags = current_tags.merge(new_resource.tags)
  if updated_tags.eql?(current_tags)
    Chef::Log.debug("AWS: Tags for resource #{new_resource.resource_id} are unchanged")
  else
    # tags that begin with "aws" are reserved
    converge_by("Updating the following tags for resource #{new_resource.resource_id} (skipping AWS tags): " + updated_tags.inspect) do
      updated_tags.delete_if { |key, _value| key.to_s =~ /^aws/ }
      ec2.create_tags(resources: [new_resource.resource_id], tags: updated_tags.collect { |k, v| { key: k, value: v } })
    end
  end
end

action :add do
  Chef::Log.debug("The current tags on the node are #{current_tags}")

  new_resource.tags.each do |k, v|
    if current_tags.keys.include?(k)
      Chef::Log.debug("AWS: Resource #{new_resource.resource_id} already has a tag with key '#{k}', will not add tag '#{k}' => '#{v}'")
    else
      converge_by("add tag '#{k}' with value '#{v}' on resource #{new_resource.resource_id}") do
        ec2.create_tags(resources: [new_resource.resource_id], tags: [{ key: k, value: v }])
      end
    end
  end
end

action :remove do
  Chef::Log.debug("The current tags on the node are #{current_tags}")

  # iterate over the tags specified for deletion
  # delete them if they exist on the node and the values match
  new_resource.tags.keys.each do |key|
    if current_tags.keys.include?(key) && current_tags[key] == new_resource.tags[key]
      converge_by("delete tag '#{key}' on resource #{new_resource.resource_id} with value '#{current_tags[key]}'") do
        ec2.delete_tags(resources: [new_resource.resource_id], tags: [{ key => new_resource.tags[key] }])
      end
    else
      Chef::Log.debug("Key #{key} not present on the node or the specified value (#{new_resource.tags[key]}) does not match the tagged value")
    end
  end
end

action :force_remove do
  Chef::Log.debug("The current tags on the node are #{current_tags}")

  new_resource.tags.keys.each do |key|
    if current_tags.keys.include?(key)
      converge_by("delete tag '#{key}' on resource #{new_resource.resource_id} with value '#{current_tags[key]}'") do
        ec2.delete_tags(resources: [new_resource.resource_id], tags: [{ key: key }])
      end
    else
      Chef::Log.debug("Key #{key} not present on the node. Skipping.")
    end
  end
end

action_class do
  include AwsCookbook::Ec2

  def current_tags
    @current_tags ||= begin
      aws_tags = {}
      ec2.describe_tags(filters: [{ name: 'resource-id', values: [new_resource.resource_id] }])[:tags].map do |tag|
        aws_tags[tag[:key]] = tag[:value]
      end
      aws_tags
    end
  end
end
