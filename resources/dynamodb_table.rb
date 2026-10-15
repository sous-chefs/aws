# frozen_string_literal: true

provides :aws_dynamodb_table
unified_mode true
default_action :create

use '_partial/_aws_common'

property :table_name, String, name_property: true
property :attribute_definitions, Array, required: true
property :key_schema, Array, required: true
property :local_secondary_indexes, Array
property :global_secondary_indexes, Array
property :provisioned_throughput, Hash, required: true
property :stream_specification, Hash, default: {}

include AwsCookbook::Ec2 # needed for aws_region helper

action :create do
  if table_state[:exists]
    do_update_throughput if table_state[:throughput_changed]
    do_update_streamspec if table_state[:stream_changed]
    do_change_gsi(:update) if table_state[:gsi_changes][:update]
    do_change_gsi(:delete) if table_state[:gsi_changes][:delete]
    do_change_gsi(:create) if table_state[:gsi_changes][:create]
  else
    do_create_table
  end
end

action :delete do
  do_delete_table if table_state[:exists]
end

action_class do
  include AwsCookbook::DynamoDB

  def table_state
    @table_state ||= begin
      resp = dynamodb.describe_table(table_name: new_resource.table_name)
      {
        exists: true,
        throughput_changed: throughput_changed?(
          resp.table.provisioned_throughput,
          new_resource.provisioned_throughput
        ),
        stream_changed: !new_resource.stream_specification.empty? && stream_changed?(
          resp.table.stream_specification,
          new_resource.stream_specification
        ),
        gsi_changes: {
          create: load_gsi_creates(
            resp.table.global_secondary_indexes,
            new_resource.global_secondary_indexes
          ),
          update: load_gsi_updates(
            resp.table.global_secondary_indexes,
            new_resource.global_secondary_indexes
          ),
          delete: load_gsi_deletes(
            resp.table.global_secondary_indexes,
            new_resource.global_secondary_indexes
          ),
        },
      }
                     rescue ::Aws::DynamoDB::Errors::ResourceNotFoundException
                       { exists: false, throughput_changed: false, stream_changed: false, gsi_changes: {} }
    end
  end

  def wait_for_table
    resource = ::Aws::DynamoDB::Resource.new(client: dynamodb)
    table = resource.table(new_resource.table_name)
    before_wait_hook = lambda do |attempts, _response|
      Chef::Log.debug("waiting for table to become active - attempt #{attempts}")
    end

    table.wait_until(before_wait: before_wait_hook, max_attempts: 30) { |waiter| waiter.table_status == 'ACTIVE' }
  end

  def throughput_changed?(api_throughput, resource_throughput)
    api_throughput.read_capacity_units != resource_throughput[:read_capacity_units] ||
      api_throughput.write_capacity_units != resource_throughput[:write_capacity_units]
  end

  def stream_changed?(api_spec, resource_spec)
    return true if api_spec.nil? && resource_spec[:stream_enabled]

    api_spec.stream_enabled != resource_spec[:stream_enabled] ||
      api_spec.stream_view_type != resource_spec[:stream_view_type]
  end

  def load_gsi_creates(api_indexes, resource_indexes)
    return unless resource_indexes

    Array(resource_indexes).filter_map do |resource_index|
      { create: resource_index } unless api_indexes&.any? { |index| index.index_name == resource_index[:index_name] }
    end
  end

  def load_gsi_updates(api_indexes, resource_indexes)
    return unless api_indexes && resource_indexes

    api_indexes.filter_map do |api_index|
      resource_index = resource_indexes.find { |index| index[:index_name] == api_index.index_name }
      next unless resource_index

      {
        update: {
          index_name: api_index.index_name,
          provisioned_throughput: resource_index[:provisioned_throughput],
        },
      } if throughput_changed?(api_index.provisioned_throughput, resource_index[:provisioned_throughput])
    end
  end

  def load_gsi_deletes(api_indexes, resource_indexes)
    return unless api_indexes && resource_indexes

    api_indexes.filter_map do |api_index|
      { delete: { index_name: api_index.index_name } } unless resource_indexes.any? { |index| index[:index_name] == api_index.index_name }
    end
  end

  def do_delete_table
    converge_by("delete DynamoDB table #{new_resource.table_name}") do
      dynamodb.delete_table(table_name: new_resource.table_name)
    end
  end

  def do_create_table
    converge_by("create DynamoDB table #{new_resource.table_name}") do
      request = {
        table_name: new_resource.table_name,
        attribute_definitions: new_resource.attribute_definitions,
        key_schema: new_resource.key_schema,
        local_secondary_indexes: new_resource.local_secondary_indexes,
        global_secondary_indexes: new_resource.global_secondary_indexes,
        provisioned_throughput: new_resource.provisioned_throughput,
        stream_specification: new_resource.stream_specification.empty? ? nil : new_resource.stream_specification,
      }.compact

      dynamodb.create_table(request)
    end
  end

  def do_update_throughput
    converge_by("change throughput on DynamoDB table #{new_resource.table_name}") do
      wait_for_table
      dynamodb.update_table(
        table_name: new_resource.table_name,
        provisioned_throughput: new_resource.provisioned_throughput
      )
    end
  end

  def do_update_streamspec
    converge_by("change stream spec on DynamoDB table #{new_resource.table_name}") do
      wait_for_table
      dynamodb.update_table(
        table_name: new_resource.table_name,
        stream_specification: new_resource.stream_specification
      )
    end
  end

  def do_change_gsi(operation)
    Array(table_state[:gsi_changes][operation]).each do |index|
      converge_by("#{operation} global secondary index #{index[operation][:index_name]} on table #{new_resource.table_name}") do
        wait_for_table
        dynamodb.update_table(
          table_name: new_resource.table_name,
          attribute_definitions: new_resource.attribute_definitions,
          global_secondary_index_updates: [index]
        )
      end
    end
  end
end
