require 'aws-sdk'
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
    region = availability_zone.chop
    region
  end
end
