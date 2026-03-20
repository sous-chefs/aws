# frozen_string_literal: true

require_relative 'ec2'

module AwsCookbook
  module STS
    def sts
      require 'aws-sdk-core'

      Chef::Log.debug('Initializing the STS Client')
      @sts ||= create_aws_interface(::Aws::STS::Client, region: new_resource.region)
    end
  end
end
