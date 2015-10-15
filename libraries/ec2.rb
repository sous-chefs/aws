#
# Copyright:: Copyright (c) 2009 Opscode, Inc.
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

# TODO: once sync_libraries properly handles sub-directories, move this file to aws/libraries/opscode/aws/ec2.rb

require 'open-uri'

module Opscode
  module Aws
    module Ec2
      def find_snapshot_id(volume_id = '', find_most_recent = false, search_tags = nil, require_existing_snapshot = true)
        snapshot_id = nil
        volume_id = '' if volume_id == nil

        response = if find_most_recent
                     if search_tags.nil?
                       # Fall through to old / default / previous behavior
                       ec2.describe_snapshots.sort { |a, b| a[:start_time] <=> b[:start_time] }
                     else
                       Chef::Log.debug("Filtering results using #{search_tags.inspect}")
                       ec2.describe_snapshots(filters: search_tags).sort { |a, b| a[:start_time] <=> b[:start_time] }
                     end
                   else
                     if search_tags.nil?
                       # Fall through to old / default / previous behavior
                       ec2.describe_snapshots.sort { |a, b| b[:start_time] <=> a[:start_time] }
                     else
                       Chef::Log.debug("Filtering results using #{search_tags.inspect}")
                       ec2.describe_snapshots(filters: search_tags).sort { |a, b| b[:start_time] <=> a[:start_time] }
                     end
                   end

        response.each do |page|
          page.snapshots.each do |snapshot|
            Chef::Log.debug("Checking #{snapshot[:volume_id]} / #{snapshot[:snapshot_id]} for readiness / use against -#{volume_id}-")
            # && snapshot_id.nil? is required to ensure only the first match is used, otherwise the last match is used.
            if ((volume_id.nil? && !search_tags.nil?) || (snapshot[:volume_id] == volume_id)) && snapshot[:state] == 'completed' && snapshot_id.nil?
              snapshot_id = snapshot[:snapshot_id]
            else
              Chef::Log.info("Not using VolumeID: #{volume_id}/#{volume_id.nil?}; Search Tags: #{search_tags.inspect}; Snapshot Volume ID: #{snapshot[:volume_id]}; Snapshot State: #{snapshot[:state]}")
            end
          end
        end

        # Allow for two scenarios:
        # 1. Building a new instance for the first time, there are no existing snapshots; this will fall through if require_existing_snapshot is 'false', and then create a new, empty volume
        # 2. Building a new instance subsequent times, after a snapshot has been created for the volume, in this case the code here should have found a snapshot and will create a volume from that snapshot
        if require_existing_snapshot
          fail 'Cannot find snapshot id!' unless snapshot_id
        end

        Chef::Log.debug("Snapshot ID is #{snapshot_id}")
        snapshot_id
      end

      def ec2
        @@ec2 ||= create_aws_interface(::Aws::EC2::Client)
      end

      def instance_id
        @@instance_id ||= query_instance_id
      end

      def instance_availability_zone
        @@instance_availability_zone ||= query_instance_availability_zone
      end

      private

      def create_aws_interface(aws_interface)
        begin
          require 'aws-sdk'
        rescue LoadError
          Chef::Log.error("Missing gem 'aws-sdk'. Use the default aws recipe to install it first.")
        end

        region = instance_availability_zone
        region = region[0, region.length - 1]

        if !new_resource.aws_access_key.to_s.empty? && !new_resource.aws_secret_access_key.to_s.empty?
          creds = ::Aws::Credentials.new(new_resource.aws_access_key, new_resource.aws_secret_access_key, new_resource.aws_session_token)
        else
          Chef::Log.info('Attempting to use iam profile')
          creds = ::Aws::InstanceProfileCredentials.new
        end
        aws_interface.new(credentials: creds, region: region)
      end

      def query_instance_id
        instance_id = open('http://169.254.169.254/latest/meta-data/instance-id', options = { proxy: false }, &:gets)
        fail 'Cannot find instance id!' unless instance_id
        Chef::Log.debug("Instance ID is #{instance_id}")
        instance_id
      end

      def query_instance_availability_zone
        availability_zone = open('http://169.254.169.254/latest/meta-data/placement/availability-zone/', options = { proxy: false }, &:gets)
        fail 'Cannot find availability zone!' unless availability_zone
        Chef::Log.debug("Instance's availability zone is #{availability_zone}")
        availability_zone
      end

      def query_mac_address(interface = 'eth0')
        node['network']['interfaces'][interface]['addresses'].select do |_, e|
          e['family'] == 'lladdr'
        end.keys.first.downcase
      end

      def query_private_ip_addresses(interface = 'eth0')
        mac = query_mac_address(interface)
        ip_addresses = open("http://169.254.169.254/latest/meta-data/network/interfaces/macs/#{mac}/local-ipv4s", options = { proxy: false }) { |f| f.read.split("\n") }
        Chef::Log.debug("#{interface} assigned local ipv4s addresses is/are #{ip_addresses.join(',')}")
        ip_addresses
      end

      def query_network_interface_id(interface = 'eth0')
        mac = query_mac_address(interface)
        eni_id = open("http://169.254.169.254/latest/meta-data/network/interfaces/macs/#{mac}/interface-id", options = { proxy: false }, &:gets)
        Chef::Log.debug("#{interface} eni id is #{eni_id}")
        eni_id
      end
    end
  end
end
