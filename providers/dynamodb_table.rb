include Opscode::Aws::DynamoDB

use_inline_resources

def whyrun_supported?
  true
end

action :create do
  load_current_resource
  if @table_exists
    do_update_throughput if @table_throughput_changed
    do_update_streamspec if @table_stream_changed
    do_change_gsi(:update) if @gsi_changes[:update]
    do_change_gsi(:delete) if @gsi_changes[:delete]
    do_change_gsi(:create) if @gsi_changes[:create]
  else
    do_create_table
  end
end

action :delete do
  load_current_resource
  do_delete_table if @table_exists
end

private

# loads the existing DynamoDB table and ensures that some surrounding logic is
# instantiated.
def load_current_resource
  resp = dynamodb.describe_table(table_name: new_resource.table_name)
  if resp.table
    @table_exists = true
    @table_throughput_changed = throughput_changed?(
      resp.table.provisioned_throughput,
      new_resource.provisioned_throughput
    )
    @table_stream_changed = stream_changed?(
      resp.table.stream_specification,
      new_resource.stream_specification
    ) if new_resource.stream_specification
    @gsi_changes = {}
    @gsi_changes[:create] = load_gsi_creates(
      resp.table.global_secondary_indexes,
      new_resource.global_secondary_indexes
    ) if new_resource.global_secondary_indexes
    @gsi_changes[:update] = load_gsi_updates(
      resp.table.global_secondary_indexes,
      new_resource.global_secondary_indexes
    ) if new_resource.global_secondary_indexes &&
         resp.table.global_secondary_indexes
    @gsi_changes[:delete] = load_gsi_deletes(
      resp.table.global_secondary_indexes,
      new_resource.global_secondary_indexes
    ) if new_resource.global_secondary_indexes &&
         resp.table.global_secondary_indexes
  else
    @table_exists = false
  end
rescue ::Aws::DynamoDB::Errors::ResourceNotFoundException
  @table_exists = false
end

private

# waits for table to become ready (and throws exception if it times out)
def wait_for_table
  res = ::Aws::DynamoDB::Resource.new(client: dynamodb)
  table = res.table(new_resource.table_name)
  before_wait_hook = lambda do |attempts, _response|
    Chef::Log.debug("waiting for table to become active - attempt #{attempts}")
  end
  table.wait_until(
    before_wait: before_wait_hook,
    max_attempts: 30
  ) { |waiter| waiter.table_status == 'ACTIVE' }
end

private

# throughput change logic (comparison for both table and GSI values)
# API spec (value from describe_table) needs to come first
def throughput_changed?(api_throughput, res_throughput)
  if api_throughput.read_capacity_units != res_throughput[:read_capacity_units] ||
     api_throughput.write_capacity_units != res_throughput[:write_capacity_units]
    true
  else
    false
  end
end

private

# check to see if table stream spec has changed (API spec first)
def stream_changed?(api_spec, res_spec)
  return true if api_spec.nil? && res_spec[:stream_enabled]
  if api_spec.stream_enabled != res_spec[:stream_enabled] ||
     api_spec.stream_view_type != res_spec[:stream_view_type]
    true
  else
    false
  end
end

private

# assembles list of new tables for the global secondary indexes, crafted
# as updates that can be sent to AWS::DynamoDB::Client.update_table
# API (from describe_table) values need to come first
def load_gsi_creates(api_indexes, res_indexes)
  creates = []
  res_indexes.each do |res_index|
    unless api_indexes && api_indexes.index { |x| x.index_name == res_index[:index_name] }
      creates.push(create: res_index)
    end
  end
  creates
end

private

# assembles list of tables to update for the global secondary indexes, crafted
# as updates that can be sent to AWS::DynamoDB::Client.update_table
# API (from describe_table) values need to come first
def load_gsi_updates(api_indexes, res_indexes)
  updates = []
  api_indexes.each do |api_index|
    res_index_id = res_indexes.index { |x| x[:index_name] == api_index.index_name }
    next unless res_index_id
    # found
    res_index = res_indexes[res_index_id]
    updates.push(
      update: {
        index_name: gsi.index_name,
        provisioned_throughput: res_index[:provisioned_throughput]
      }
    ) if throughput_changed?(
      api_index.provisioned_throughput, res_index[:provisioned_throughput]
    )
  end
  updates
end

private

# assembles list of tables to delete for the global secondary indexes, crafted
# as updates that can be sent to AWS::DynamoDB::Client.update_table
# API (from describe_table) values need to come first
def load_gsi_deletes(api_indexes, res_indexes)
  deletes = []
  api_indexes.each do |api_index|
    unless res_indexes.index { |x| x[:index_name] == api_index.index_name }
      deletes.push(delete: { index_name: api_index.index_name })
    end
  end
  deletes
end

private

# performs the delete action on the table.
def do_delete_table
  converge_by("delete DynamoDB table #{new_resource.table_name}") do
    dynamodb.delete_table(table_name: new_resource.table_name)
    new_resource.updated_by_last_action(true)
  end
end

private

# creates the table
def do_create_table
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
    new_resource.updated_by_last_action(true)
  end
end

private

# updates general throughput for the table
def do_update_throughput
  converge_by("change throughput on DynamoDB table #{new_resource.table_name}") do
    # wait for table to become ready (if it is not)
    wait_for_table
    dynamodb.update_table(
      table_name: new_resource.table_name,
      provisioned_throughput: new_resource.provisioned_throughput
    )
    new_resource.updated_by_last_action(true)
  end
end

private

# updates the stream specification for a table
def do_update_streamspec
  converge_by("change stream spec on DynamoDB table #{new_resource.table_name}") do
    # wait for table to become ready (if it is not)
    wait_for_table
    dynamodb.update_table(
      table_name: new_resource.table_name,
      stream_specification: new_resource.stream_specification
    )
    new_resource.updated_by_last_action(true)
  end
end

private

# performs specific change operations
def do_change_gsi(op)
  @gsi_changes[op].each do |index|
    converge_by(
      "#{op} global secondary index #{index[op][:index_name]} " \
      "on table #{new_resource.table_name}"
    ) do
      wait_for_table
      dynamodb.update_table(
        table_name: new_resource.table_name,
        attribute_definitions: new_resource.attribute_definitions,
        global_secondary_index_updates: [index]
      )
      new_resource.updated_by_last_action(true)
    end
  end
end
