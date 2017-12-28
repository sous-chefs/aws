#
# Copyright:: 2009-2016, Chef Software, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

module AwsCookbook
  module Ec2
    def ec2
      require 'aws-sdk'

      Chef::Log.debug('Initializing the EC2 Client')
      @ec2 ||= create_aws_interface(::Aws::EC2::Client, region: new_resource.region)
    end

    def instance_id
      node['ec2']['instance_id']
    end

    def find_snapshot_id(volume_id = '', find_most_recent = false)
      response = ec2.describe_snapshots(
        filters: [
          { name: 'volume-id', values: [volume_id] },
          { name: 'status', values: ['completed'] },
        ]
      )
      snapshots = if find_most_recent
                    # bring the latest snapshot to the front
                    response.snapshots.sort { |a, b| b[:start_time] <=> a[:start_time] }
                  else
                    response.snapshots.sort { |a, b| a[:start_time] <=> b[:start_time] }
                  end

      raise 'Cannot find snapshot id!' if snapshots.empty?

      Chef::Log.debug("Snapshot ID is #{snapshots.first[:snapshot_id]}")
      snapshots.first[:snapshot_id]
    end

    # determine the AWS region to fallback to for resources
    # which haven't specified a region
    # Priority: ohai data -> us-east-1
    def fallback_region
      # facilitate support for region in resource name
      if node.attribute?('ec2')
        Chef::Log.debug("Using region #{node['ec2']['placement_availability_zone'].chop} from Ohai attributes")
        node['ec2']['placement_availability_zone'].chop
      else
        Chef::Log.debug('Falling back to region us-east-1 as Ohai data and resource defined region not present')
        'us-east-1'
      end
    end

    # setup AWS instance using passed creds, iam profile, or assumed role
    def create_aws_interface(aws_interface, **opts)
      aws_interface_opts = { region: opts[:region] }

      if opts[:mock] # return a mocked interface
        aws_interface_opts[:stub_responses] = true
      else # return a real interface with credentials setup
        if !new_resource.aws_access_key.to_s.empty? && !new_resource.aws_secret_access_key.to_s.empty?
          Chef::Log.debug('Using resource-defined credentials')
          aws_interface_opts[:credentials] = ::Aws::Credentials.new(
            new_resource.aws_access_key,
            new_resource.aws_secret_access_key,
            new_resource.aws_session_token
          )
        else
          Chef::Log.debug('Using local credential chain')
        end

        if !new_resource.aws_assume_role_arn.to_s.empty? && !new_resource.aws_role_session_name.to_s.empty?
          Chef::Log.debug("Assuming role #{new_resource.aws_assume_role_arn}")
          sts_client = ::Aws::STS::Client.new(region: opts[:region],
                                              access_key_id: new_resource.aws_access_key,
                                              secret_access_key: new_resource.aws_secret_access_key)
          creds = ::Aws::AssumeRoleCredentials.new(client: sts_client, role_arn: new_resource.aws_assume_role_arn, role_session_name: new_resource.aws_role_session_name)
          aws_interface_opts[:credentials] = creds
        end
      end

      Chef::Log.debug("Initializing interface with client interface options: #{aws_interface_opts}")
      aws_interface.new(aws_interface_opts)
    end
  end
end
