require 'aws-sdk-core'
require 'aws-sdk-dynamodb'

class ChefAwsDDBTest
  attr_reader :dynamodb

  def initialize
    @dynamodb = ::Aws::DynamoDB::Client.new(
      credentials: ::Aws::InstanceProfileCredentials.new,
      region: instance_region
    )
  end

  def instance_region
    ::Aws::EC2Metadata.new.get('/latest/meta-data/placement/region')
  end
end
