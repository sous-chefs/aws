aws_dynamodb_table 'kitchen-test-table' do
  action :create
  attribute_definitions [
    { attribute_name: 'Id', attribute_type: 'N' },
    { attribute_name: 'Foo', attribute_type: 'S' },
  ]
  key_schema [
    { attribute_name: 'Id', key_type: 'HASH' }
  ]
  global_secondary_indexes [
    {
      index_name: 'FooIndex',
      key_schema: [{
        attribute_name: 'Foo',
        key_type: 'HASH'
      }],
      projection: {
        projection_type: 'ALL'
      },
      provisioned_throughput: {
        read_capacity_units: 1,
        write_capacity_units: 1
      }
    }
  ]
  provisioned_throughput ({
    read_capacity_units: 1,
    write_capacity_units: 1
  })
end
