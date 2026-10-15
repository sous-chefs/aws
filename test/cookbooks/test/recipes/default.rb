# frozen_string_literal: true

ENV['AWS_COOKBOOK_STUB_RESPONSES'] = 'true'

require 'aws-sdk-dynamodb'

marker_path = '/tmp/aws-default-suite-ran'
table_exists = ::File.exist?(marker_path)

Aws.config.update(
  dynamodb: {
    stub_responses: {
      describe_table: if table_exists
                        {
                          table: {
                            table_name: 'codex-default',
                            provisioned_throughput: {
                              read_capacity_units: 1,
                              write_capacity_units: 1,
                            },
                            stream_specification: nil,
                            global_secondary_indexes: [],
                          },
                        }
                      else
                        'ResourceNotFoundException'
                      end,
      create_table: {
        table_description: {
          table_name: 'codex-default',
          table_status: 'ACTIVE',
        },
      },
    },
  }
)

aws_dynamodb_table 'codex-default' do
  attribute_definitions([{ attribute_name: 'id', attribute_type: 'S' }])
  key_schema([{ attribute_name: 'id', key_type: 'HASH' }])
  provisioned_throughput(read_capacity_units: 1, write_capacity_units: 1)
end

file marker_path do
  content 'default suite converged'
  mode '0644'
end
