include Opscode::Aws::Ec2

action :add do
  unless @new_resource.resource_id
    resource_id = @new_resource.name
  else
    resource_id = @new_resource.resource_id
  end

  existing_tags = Hash.new
  ec2.describe_tags(:filters => { 'resource-id' => resource_id }).map {|tag| existing_tags[tag[:key]] = tag[:value] }

  @new_resource.tags.each do |k,v|
    unless existing_tags.keys.include?(k)
      ec2.create_tags(resource_id, { k => v })
      Chef::Log.info("AWS: Added tag '#{k}' with value '#{v}' on resource #{resource_id}")
      new_resource.updated_by_last_action(true)
    else
      Chef::Log.debug("AWS: Resource #{resource_id} already has a tag with key '#{k}', will not add tag '#{k}' => '#{v}'")
      new_resource.updated_by_last_action(false)
    end
  end
end

action :update do
  unless @new_resource.resource_id
    resource_id = @new_resource.name
  else
    resource_id = @new_resource.resource_id
  end

  existing_tags = Hash.new
  ec2.describe_tags(:filters => { 'resource-id' => resource_id }).map {|tag| existing_tags[tag[:key]] = tag[:value] }
  updated_tags = existing_tags.merge(@new_resource.tags)
  unless updated_tags.eql?(existing_tags)
    Chef::Log.info("AWS: Updating the following tags for resource #{resource_id}: " + updated_tags.inspect)
    ec2.create_tags(resource_id, updated_tags)
    new_resource.updated_by_last_action(true)
  else
    Chef::Log.debug("AWS: Tags for resource #{resource_id} are unchanged")
    new_resource.updated_by_last_action(false)
  end
end

action :remove do
  unless @new_resource.resource_id
    resource_id = @new_resource.name
  else
    resource_id = @new_resource.resource_id
  end

  existing_tags = Hash.new
  ec2.describe_tags(:filters => { 'resource-id' => resource_id }).map {|tag| existing_tags[tag[:key]] = tag[:value] }
  tags_to_delete = @new_resource.tags.keys

  tags_to_delete.each do |key|
    if existing_tags.keys.include?(key) and existing_tags[key] == @new_resource.tags[key]
      ec2.delete_tags(resource_id, {key => @new_resource.tags[key]})
      Chef::Log.info("AWS: Deleted tag '#{key}' on resource #{resource_id} with value '#{existing_tags[key]}'")
      new_resource.updated_by_last_action(true)
    end
  end
end

action :force_remove do
  unless @new_resource.resource_id
    resource_id = @new_resource.name
  else
    resource_id = @new_resource.resource_id
  end

  existing_tags = Hash.new
  ec2.describe_tags(:filters => { 'resource-id' => resource_id }).map {|tag| existing_tags[tag[:key]] = tag[:value] }
  tags_to_delete = @new_resource.tags.keys

  tags_to_delete.each do |key|
    if existing_tags.keys.include?(key)
      ec2.delete_tags(resource_id, key)
      Chef::Log.info("AWS: Deleted tag '#{key}' on resource #{resource_id} with value '#{existing_tags[key]}'")
      new_resource.updated_by_last_action(true)
    end
  end
end
