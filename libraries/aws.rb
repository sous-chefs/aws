#
# Copyright:: Copyright (c) 2015-2016 Chef Software, Inc.
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
module Opscode
  module Aws
    def require_aws_sdk
      # require the version of the aws-sdk specified in the node attribute
      gem 'aws-sdk', node['aws']['aws_sdk_version']
      require 'aws-sdk'
      Chef::Log.debug("Node had aws-sdk #{node['aws']['aws_sdk_version']} installed. No need to install gem.")
    rescue LoadError
      Chef::Log.debug("Did not find aws-sdk version #{node['aws']['aws_sdk_version']} installed. Installing now")

      chef_gem 'aws-sdk' do
        version node['aws']['aws_sdk_version']
        compile_time true if Chef::Resource::ChefGem.method_defined?(:compile_time)
        action :install
      end

      require 'aws-sdk'
    end
  end
end
