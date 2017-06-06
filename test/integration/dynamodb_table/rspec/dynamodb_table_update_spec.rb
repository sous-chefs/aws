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
  it 'new global secondary index attribute exists' do
    attribute_name = resp.table.attribute_definitions.index do |x|
      x.attribute_name == 'Booze'
    end
    expect(attribute_name).to be
  end
  it 'expects the global secondary index to have changed' do
    expect(resp.table.global_secondary_indexes[0].index_name).to eq 'BoozeIndex'
  end
  it 'expects the changed throughput (read)' do
    expect(resp.table.provisioned_throughput.read_capacity_units).to eq 3
  end
  it 'expects the changed throughput (write)' do
    expect(resp.table.provisioned_throughput.write_capacity_units).to eq 3
  end
  it 'expects stream specification to be disabled (empty)' do
    expect(resp.table.stream_specification).to be_nil
  end
end
