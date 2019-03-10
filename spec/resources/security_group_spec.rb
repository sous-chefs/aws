require 'spec_helper'
require 'chef'
require 'aws-sdk-ec2'
require_relative '../../libraries/ec2'

describe 'aws_security_group' do
  step_into %w(aws_security_group)
  platform 'ubuntu'
  let(:ec2_client) { Aws::EC2::Client.new(stub_responses: true) }

  before :all do
    # IMPORTANT - OTHERWISE LIVE CALLS TO AWS WILL BE PERFORMED
    # http://docs.aws.amazon.com/sdkforruby/api/Aws/ClientStubs.html
    Aws.config[:stub_responses] = true
  end

  context 'should create a security group when it does not exist' do
    recipe do
      aws_security_group 'hello_world' do
        description 'hello_world_description'
        vpc_id 'vpc-00000000'
        action :create
      end
    end

    it {
      # Set up mocks
      describe_security_groups_stub = ec2_client.stub_data(
        :describe_security_groups,
          security_groups: []
      )
      ec2_client.stub_responses(:describe_security_groups, describe_security_groups_stub)
      create_security_group_stub = ec2_client.stub_data(
        :create_security_group,
          group_id: '12345'
      )
      ec2_client.stub_responses(:create_security_group, create_security_group_stub)
      allow(Aws::EC2::Client).to receive(:new).and_return(ec2_client)

      # Run the recipe and expect that a security group is created
      expect { chef_run }.to_not raise_error
      expect(chef_run).to create_aws_security_group('hello_world').with(
        description: 'hello_world_description',
        vpc_id: 'vpc-00000000')

      # Find the recorded request and validate it was made with the correct params
      create_security_group_request = ec2_client.api_requests.find do |req|
        req[:operation_name] == :create_security_group
      end
      expect(create_security_group_request[:params]).to eq(description: 'hello_world_description',
                                                           group_name: 'hello_world',
                                                           vpc_id: 'vpc-00000000')
    }
  end

  context 'should not create a security group which already exists' do
    recipe do
      aws_security_group 'security_group_name' do
        description 'security_group_description'
        vpc_id 'vpc-00000000'
        action :create
      end
    end

    it {
      # Mock the ec2 data
      describe_security_groups_stub = ec2_client.stub_data(
        :describe_security_groups,
          security_groups:  [{ description: 'security_group_description',
                               group_name: 'security_group_name',
                               ip_permissions: [],
                               owner_id: '333333333333',
                               group_id: 'sg-00000000000000000',
                               ip_permissions_egress: [],
                               tags: [
                                   { key: 'tag_key', value: 'tag_value' },
                               ],
                               vpc_id: 'vpc-00000000',
                             }]
      )
      ec2_client.stub_responses(:describe_security_groups, describe_security_groups_stub)
      allow(Aws::EC2::Client).to receive(:new).and_return(ec2_client)

      # Run the recipe
      expect { chef_run }.to_not raise_error
      expect(chef_run).to create_aws_security_group('security_group_name')

      # Expect that it doesn't try to create a security group
      create_security_group_request = ec2_client.api_requests.find do |req|
        req[:operation_name] == :create_security_group
      end
      expect(create_security_group_request).to eq(nil)
    }
  end
end
