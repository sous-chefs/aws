require 'aws-sdk'

default_action :create
actions :create, :delete

attribute :table_name, kind_of: String, name_attribute: true
attribute :attribute_definitions, kind_of: Array, required: true, callbacks: {
  'should contain valid Aws::DynamoDB::Types::AttributeDefinition types' => lambda do |attrs|
    attrs.each do |attr|
      return false unless Chef::Resource::AwsDynamodbTable.valid_attr?(::Aws::DynamoDB::Types::AttributeDefinition, attr)
    end
    true
  end
}

attribute :key_schema, kind_of: Array, required: true, callbacks: {
  'should contain valid Aws::DynamoDB::Types::KeySchemaElement types' => lambda do |attrs|
    attrs.each do |attr|
      return false unless Chef::Resource::AwsDynamodbTable.valid_attr?(::Aws::DynamoDB::Types::KeySchemaElement, attr)
    end
    true
  end
}

attribute :local_secondary_indexes, kind_of: Array, default: nil, callbacks: {
  'should contain valid Aws::DynamoDB::Types::LocalSecondaryIndex types' => lambda do |attrs|
    attrs.each do |attr|
      return false unless Chef::Resource::AwsDynamodbTable.valid_attr?(::Aws::DynamoDB::Types::LocalSecondaryIndex, attr)
    end
    true
  end
}

attribute :global_secondary_indexes, kind_of: Array, default: nil, callbacks: {
  'should contain valid Aws::DynamoDB::Types::GlobalSecondaryIndex types' => lambda do |attrs|
    attrs.each do |attr|
      return false unless Chef::Resource::AwsDynamodbTable.valid_attr?(::Aws::DynamoDB::Types::GlobalSecondaryIndex, attr)
    end
    true
  end
}

attribute :provisioned_throughput, kind_of: Hash, required: true, callbacks: {
  'should contain valid Aws::DynamoDB::Types::ProvisionedThroughput types' => lambda do |attr|
    Chef::Resource::AwsDynamodbTable.valid_attr?(::Aws::DynamoDB::Types::ProvisionedThroughput, attr)
  end
}

attribute :stream_specification, kind_of: Hash, default: nil, callbacks: {
  'should contain valid Aws::DynamoDB::Types::StreamSpecification types' => lambda do |attr|
    Chef::Resource::AwsDynamodbTable.valid_attr?(::Aws::DynamoDB::Types::StreamSpecification, attr)
  end
}
# AWS common attributes
attribute :region, kind_of: String, default: nil
attribute :aws_access_key, kind_of: String, default: nil
attribute :aws_secret_access_key, kind_of: String, default: nil
attribute :aws_session_token, kind_of: String, default: nil

private

def self.valid_attr?(attribute_class, attribute_value)
  attr_obj = attribute_class.new(attribute_value)
  if attr_obj.is_a?(attribute_class)
    true
  else
    false
  end
rescue NameError
  false
end
