require_relative '../../../kitchen/data/rspec_helper'

describe command('/opt/chef/embedded/bin/gem list') do
  its('stdout') { should match /aws-sdk \(/ }
end

describe ChefAwsDDBTest do
  dynamodb = ChefAwsDDBTest.new.dynamodb
  resp = dynamodb.describe_table(table_name: 'test-dynamodb-table')

  it 'expects the table to be created' do
    expect(resp.table.table_name).to eq 'test-dynamodb-table'
  end
  it 'key schema attribute exists (attr #1)' do
    expect(resp.table.key_schema[0].attribute_name).to eq 'Id'
  end
  it 'expects a local secondary index to be created' do
    expect(resp.table.local_secondary_indexes[0].index_name).to eq 'BarIndex'
  end
  it 'expects a global secondary index to be created' do
    expect(resp.table.global_secondary_indexes[0].index_name).to eq 'BazIndex'
  end
  it 'expects the correct throughput (read)' do
    expect(resp.table.provisioned_throughput.read_capacity_units).to eq 2
  end
  it 'expects the correct throughput (write)' do
    expect(resp.table.provisioned_throughput.write_capacity_units).to eq 2
  end
  it 'expects stream specification to be set correctly' do
    expect(resp.table.stream_specification.stream_view_type).to eq 'KEYS_ONLY'
  end
end
