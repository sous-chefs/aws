aws_dynamodb_table 'test-dynamodb-table' do
  aws_access_key node['aws_test']['key_id']
  aws_secret_access_key node['aws_test']['access_key']
  action :create
  attribute_definitions [
    { attribute_name: 'Id', attribute_type: 'N' },
    { attribute_name: 'Foo', attribute_type: 'N' },
    { attribute_name: 'Bar', attribute_type: 'N' },
    { attribute_name: 'Baz', attribute_type: 'S' }
  ]
  key_schema [
    { attribute_name: 'Id', key_type: 'HASH' },
    { attribute_name: 'Foo', key_type: 'RANGE' }
  ]
  local_secondary_indexes [
    {
      index_name: 'BarIndex',
      key_schema: [
        {
          attribute_name: 'Id',
          key_type: 'HASH'
        },
        {
          attribute_name: 'Bar',
          key_type: 'RANGE'
        }
      ],
      projection: {
        projection_type: 'ALL'
      }
    }
  ]
  global_secondary_indexes [
    {
      index_name: 'BazIndex',
      key_schema: [{
        attribute_name: 'Baz',
        key_type: 'HASH'
      }],
      projection: {
        projection_type: 'ALL'
      },
      provisioned_throughput: {
        read_capacity_units: 2,
        write_capacity_units: 2
      }
    }
  ]
  provisioned_throughput ({
    read_capacity_units: 2,
    write_capacity_units: 2
  })
  stream_specification ({
    stream_enabled: true,
    stream_view_type: 'KEYS_ONLY'
  })
end
