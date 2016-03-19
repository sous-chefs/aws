#
# Cookbook Name:: aws
# Recipe:: default
#
# Copyright 2008-2015, Chef Software, Inc.
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

chef_gem 'aws-sdk' do
  version node['aws']['aws_sdk_version']
  compile_time true if Chef::Resource::ChefGem.instance_methods(false).include?(:compile_time)
  source 'https://ruby.taobao.org/' if node['aws']['region'].eql?('cn-north-1')
  clear_sources true if node['aws']['region'].eql?('cn-north-1')
  action :install
end

require 'aws-sdk'
