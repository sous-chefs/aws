require 'aws-sdk-dynamodb'
require 'open-uri'

class ChefAwsDDBTest
  attr_reader :dynamodb

  def initialize
    @dynamodb = ::Aws::DynamoDB::Client.new(
      credentials: ::Aws::InstanceProfileCredentials.new,
      region: instance_region
    )
  end

  def instance_region
    availability_zone = open(
      'http://169.254.169.254' \
      '/latest/meta-data/placement/availability-zone/',
      proxy: nil, &:gets
    )
    availability_zone.chop
  end
end
