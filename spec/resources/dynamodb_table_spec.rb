# frozen_string_literal: true

require 'spec_helper'

describe 'aws_dynamodb_table' do
  step_into %w(aws_dynamodb_table)
  platform 'ubuntu'

  recipe do
    aws_dynamodb_table 'example-table' do
      attribute_definitions([{ attribute_name: 'id', attribute_type: 'S' }])
      key_schema([{ attribute_name: 'id', key_type: 'HASH' }])
      provisioned_throughput({ read_capacity_units: 1, write_capacity_units: 1 })
      action :nothing
    end
  end

  it 'compiles cleanly' do
    expect { chef_run }.not_to raise_error
  end
end
