require_relative '../../../kitchen/data/rspec_helper'

describe 'DynamoDB configuration' do
  before(:all) do
    @dynamodb = ChefAwsDDBTest.new.dynamodb
    @table_name = 'test-dynamodb-table'
    @resp = @dynamodb.describe_table(table_name: @table_name)
  end

  it 'checks for the aws-sdk gem' do
    gem_list = command('/opt/chef/embedded/bin/gem list')
    expect(gem_list.stdout).to match(/aws-sdk \(/)
  end

  it 'expects the table to be created' do
    expect(@resp.table.table_name).to eq @table_name
  end

  it 'checks for the existence of the new global secondary index attribute' do
    attribute = @resp.table.attribute_definitions.find { |x| x.attribute_name == 'Booze' }
    expect(attribute).not_to be_nil
  end

  it 'expects the global secondary index to have changed' do
    gsi = @resp.table.global_secondary_indexes.find { |x| x.index_name == 'BoozeIndex' }
    expect(gsi).not_to be_nil
  end

  it 'expects the changed throughput (read)' do
    expect(@resp.table.provisioned_throughput.read_capacity_units).to eq 3
  end

  it 'expects the changed throughput (write)' do
    expect(@resp.table.provisioned_throughput.write_capacity_units).to eq 3
  end

  it 'expects stream specification to be disabled (empty)' do
    expect(@resp.table.stream_specification).to be_nil
  end
end
