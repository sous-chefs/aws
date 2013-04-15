#
# Copyright:: Copyright (c) 2013 Julio Arias.
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

# TODO: once sync_libraries properly handles sub-directories, move this file to aws/libraries/opscode/aws/rds.rb

require 'open-uri'

module Opscode
  module Aws
    module Rds
      def rds
        begin
          require 'right_aws'
        rescue LoadError
          Chef::Log.error("Missing gem 'right_aws'. Use the default aws recipe to install it first.")
        end

        region = instance_availability_zone
        region = region[0, region.length-1]
        @@rds ||= RightAws::RdsInterface.new(new_resource.aws_access_key, new_resource.aws_secret_access_key, { :logger => Chef::Log, :region => region })
      end

      def instance_id
        @@instance_id ||= query_instance_id
      end

      def instance_availability_zone
        @@instance_availability_zone ||= query_instance_availability_zone
      end

      private

      def query_instance_id
        instance_id = open('http://169.254.169.254/latest/meta-data/instance-id'){|f| f.gets}
        raise "Cannot find instance id!" unless instance_id
        Chef::Log.debug("Instance ID is #{instance_id}")
        instance_id
      end

      def query_instance_availability_zone
        availability_zone = open('http://169.254.169.254/latest/meta-data/placement/availability-zone/'){|f| f.gets}
        raise "Cannot find availability zone!" unless availability_zone
        Chef::Log.debug("Instance's availability zone is #{availability_zone}")
        availability_zone
      end
    end
  end
end
