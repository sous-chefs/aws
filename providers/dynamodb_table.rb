include Opscode::Aws::DynamoDB

def whyrun_supported?
  true
end

# check to see if the table exists
def table_exists?
  resp = dynamodb.describe_table(table_name: new_resource.table_name)
  if resp.length > 0
    true
  else
    false
  end
rescue ::Aws::DynamoDB::Errors::ResourceNotFoundException
  false
end

# check to see if throughput (on table itself) has changed
# NOTE: old_throughput needs to be a value from API, and
# new_throughput needs to be from resource
def throughput_changed?(old_throughput, new_throughput)
  if old_throughput.read_capacity_units != new_throughput[:read_capacity_units] ||
     old_throughput.write_capacity_units != new_throughput[:write_capacity_units]
    true
  else
    false
  end
end

# check to see if table stream spec has changed
def stream_spec_changed?
  resp = dynamodb.describe_table(table_name: new_resource.table_name)
  if resp.table.stream_specification
    if resp.table.stream_specification.stream_enabled != new_resource.stream_specification[:stream_enabled] ||
       resp.table.stream_specification.stream_view_type != new_resource.stream_specification[:stream_view_type]
      true
    else
      false
    end
  elsif new_resource.stream_specification
    new_resource.stream_specification[:stream_enabled]
  else
    false
  end
end

# assembles list of updates for the global secondary index
def gsi_changes
  resp = dynamodb.describe_table(table_name: new_resource.table_name)
  global_secondary_index_updates = []
  # only run if indexes are defined in resource
  if new_resource.global_secondary_indexes
    if resp.table.global_secondary_indexes
      existing_indexes = resp.table.global_secondary_indexes
    else
      existing_indexes = []
    end
    existing_indexes.each do |gsi|
      index = new_resource.global_secondary_indexes.index { |x| x[:index_name] == gsi.index_name }
      if index
        # found
        if throughput_changed?(gsi.provisioned_throughput, new_resource.global_secondary_indexes[index][:provisioned_throughput])
          global_secondary_index_updates.push(
            update: {
              index_name: gsi.index_name,
              provisioned_throughput: new_resource.global_secondary_indexes[index][:provisioned_throughput]
            }
          )
        end
      else
        # not found - delete
        global_secondary_index_updates.push(delete: { index_name: gsi.index_name })
      end
    end
    # reverse check to see if anything needs to be created
    new_resource.global_secondary_indexes.each do |gsi|
      unless existing_indexes.index { |x| x.index_name == gsi[:index_name] }
        global_secondary_index_updates.push(create: gsi)
      end
    end
  end
  global_secondary_index_updates
end

# waits for a table to become ready (and throws exception if it times out)
def wait_for_table
  res = ::Aws::DynamoDB::Resource.new(client: dynamodb)
  table = res.table(new_resource.table_name)
  before_wait_hook = lambda do |attempts, response|
    Chef::Log.debug("waiting for table to become active - attempt #{attempts}")
  end
  table.wait_until(before_wait: before_wait_hook, max_attempts: 30) { |waiter| waiter.table_status == 'ACTIVE' }
end

action :create do
  if table_exists?
    # Keys, and local secondary indexes are ignored on update. Attributes are
    # through when we update global secondary indexes.
    # update throughput
    if throughput_changed?(dynamodb.describe_table(table_name: new_resource.table_name).table.provisioned_throughput, new_resource.provisioned_throughput)
      converge_by("change throughput on DynamoDB table #{new_resource.table_name}") do
        # wait for table to become ready (if it is not)
        wait_for_table
        dynamodb.update_table(
          table_name: new_resource.table_name,
          provisioned_throughput: new_resource.provisioned_throughput
        )
      end
    end
    # update stream spec
    if stream_spec_changed?
      converge_by("change stream spec on DynamoDB table #{new_resource.table_name}") do
        # wait for table to become ready (if it is not)
        wait_for_table
        dynamodb.update_table(
          table_name: new_resource.table_name,
          stream_specification: new_resource.stream_specification
        )
      end
    end
    # get list of changes to global secondary indexes
    global_secondary_index_updates = gsi_changes
    Chef::Log.debug("gsi_changes dump: #{gsi_changes}")
    # update existing indexes
    [:update, :delete, :create].each do |op|
      (global_secondary_index_updates.select { |update| update.keys.include?(op) }).each do |index|
        converge_by("update global secondary index #{index[op][:index_name]} on table #{new_resource.table_name}") do
          wait_for_table
          dynamodb.update_table(
            table_name: new_resource.table_name,
            attribute_definitions: new_resource.attribute_definitions,
            global_secondary_index_updates: [index]
          )
        end
      end
    end
  else
    converge_by("create DynamoDB table #{new_resource.table_name}") do
      dynamodb.create_table(
        table_name: new_resource.table_name,
        attribute_definitions: new_resource.attribute_definitions,
        key_schema: new_resource.key_schema,
        local_secondary_indexes: new_resource.local_secondary_indexes,
        global_secondary_indexes: new_resource.global_secondary_indexes,
        provisioned_throughput: new_resource.provisioned_throughput,
        stream_specification: new_resource.stream_specification
      )
    end
  end
end

action :delete do
  if table_exists?
    converge_by("delete DynamoDB table #{new_resource.table_name}") do
      dynamodb.delete_table(table_name: new_resource.table_name)
    end
  end
end
