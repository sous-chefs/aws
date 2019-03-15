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
      # First call should return empty
      describe_security_groups_stub_before = ec2_client.stub_data(
        :describe_security_groups, security_groups: [])
      # Subsequent call it should return the group
      describe_security_groups_stub_after = ec2_client.stub_data(
        :describe_security_groups,
          security_groups:
              [{
                description: 'hello_world_description',
                group_name: 'hello_world',
                ip_permissions: [],
                ip_permissions_egress: [],
                owner_id: '333333333333',
                group_id: 'sg-00000000000000000',
                tags: [],
              }]
      )
      ec2_client.stub_responses(:describe_security_groups, describe_security_groups_stub_before, describe_security_groups_stub_after)
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
          security_groups:
              [{
                description: 'security_group_description',
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

  context 'should not update tags' do
    recipe do
      aws_security_group 'security_group_name' do
        description 'security_group_description'
        vpc_id 'vpc-00000000'
        tags [
          {
            key: 'Stack',
            value: 'production',
          },
          {
            key: 'CreatedBy',
            value: 'Chef',
          },
        ]
        action :create
      end
    end

    it {
      # Mock the ec2 data
      describe_security_groups_stub = ec2_client.stub_data(
        :describe_security_groups,
          security_groups:
              [{
                description: 'security_group_description',
                group_name: 'security_group_name',
                ip_permissions: [],
                owner_id: '333333333333',
                group_id: 'sg-00000000000000000',
                ip_permissions_egress: [],
                tags: [
                  {
                    key: 'CreatedBy',
                    value: 'Chef',
                  },
                  {
                    key: 'Stack',
                    value: 'production',
                  },
                ],
                vpc_id: 'vpc-00000000',
              }]
      )
      ec2_client.stub_responses(:describe_security_groups, describe_security_groups_stub)
      allow(Aws::EC2::Client).to receive(:new).and_return(ec2_client)

      # Run the recipe
      expect { chef_run }.to_not raise_error
      expect(chef_run).to create_aws_security_group('security_group_name')

      # Expect that it doesn't try to create tags
      create_tags_request = ec2_client.api_requests.find do |req|
        req[:operation_name] == :create_tags
      end
      expect(create_tags_request).to eq(nil)
    }
  end

  context 'should create and delete update tags' do
    recipe do
      aws_security_group 'security_group_name' do
        description 'security_group_description'
        vpc_id 'vpc-00000000'
        tags [
          {
            key: 'ChefTag',
            value: 'ToAdd',
          },
          {
            key: 'Tag',
            value: 'ToKeep',
          },
        ]
        action :create
      end
    end

    it {
      # Mock the ec2 data
      describe_security_groups_stub = ec2_client.stub_data(
        :describe_security_groups,
          security_groups:
              [{
                description: 'security_group_description',
                group_name: 'security_group_name',
                ip_permissions: [],
                owner_id: '333333333333',
                group_id: 'sg-00000000000000000',
                ip_permissions_egress: [],
                tags: [
                  {
                    key: 'AwsTag',
                    value: 'ToRemove',
                  },
                  {
                    key: 'Tag',
                    value: 'ToKeep',
                  },
                ],
                vpc_id: 'vpc-00000000',
              }]
      )
      ec2_client.stub_responses(:describe_security_groups, describe_security_groups_stub)
      allow(Aws::EC2::Client).to receive(:new).and_return(ec2_client)

      # Run the recipe
      expect { chef_run }.to_not raise_error
      expect(chef_run).to create_aws_security_group('security_group_name')

      # Expect that it creates tags
      create_tags_request = ec2_client.api_requests.find do |req|
        req[:operation_name] == :create_tags
      end
      expect(create_tags_request[:params][:tags].length).to eq(1)
      expect(create_tags_request[:params][:tags][0][:key]).to eq('ChefTag')
      expect(create_tags_request[:params][:tags][0][:value]).to eq('ToAdd')

      # Expect that it deletes tags
      delete_tags_request = ec2_client.api_requests.find do |req|
        req[:operation_name] == :delete_tags
      end
      expect(delete_tags_request[:params][:tags].length).to eq(1)
      expect(delete_tags_request[:params][:tags][0][:key]).to eq('AwsTag')
      expect(delete_tags_request[:params][:tags][0][:value]).to eq('ToRemove')
    }
  end

  context 'should not update ingress/egress rules even when properties unsorted' do
    recipe do
      aws_security_group 'security_group_name' do
        description 'security_group_description'
        ip_permissions [{
          ip_protocol: 'tcp',
          ip_ranges: [
            {

              description: 'SSH access from the NY office',
              cidr_ip: '10.10.10.20/24',
            },
          ],
          from_port: 22,
          to_port: 22,
        },
                        {
                          from_port: 99,
                          ip_protocol: 'tcp',
                          ip_ranges: [
                            {
                              cidr_ip: '10.10.10.10/24',
                              description: 'SSH access from the LA office',
                            },
                          ],
                          to_port: 99,
                        }]
        ip_permissions_egress [{
          ip_protocol: 'udp',
          ip_ranges: [
            {

              description: 'UDP access from the NY office',
              cidr_ip: '10.10.10.20/24',
            },
          ],
          from_port: 2202,
          to_port: 2202,
        },
                               {
                                 from_port: 9909,
                                 ip_protocol: 'udp',
                                 ip_ranges: [
                                   {
                                     cidr_ip: '10.10.10.10/24',
                                     description: 'UDP access from the LA office',
                                   },
                                 ],
                                 to_port: 9909,
                               }]
        vpc_id 'vpc-00000000'
        action :create
      end
    end

    it {
      # Mock the ec2 data
      describe_security_groups_stub = ec2_client.stub_data(
        :describe_security_groups,
          security_groups:
              [{
                description: 'security_group_description',
                group_name: 'security_group_name',
                ip_permissions: [{
                  from_port: 99,
                  ip_protocol: 'tcp',
                  ip_ranges: [
                    {
                      cidr_ip: '10.10.10.10/24',
                      description: 'SSH access from the LA office',
                    },
                  ],
                  to_port: 99,
                }, {
                  from_port: 22,
                  ip_protocol: 'tcp',
                  ip_ranges: [
                    {
                      cidr_ip: '10.10.10.20/24',
                      description: 'SSH access from the NY office',

                    },
                  ],
                  to_port: 22,
                }
                                                 ],
                owner_id: '333333333333',
                group_id: 'sg-00000000000000000',
                ip_permissions_egress: [{
                  from_port: 9909,
                  ip_protocol: 'udp',
                  ip_ranges: [
                    {
                      cidr_ip: '10.10.10.10/24',
                      description: 'UDP access from the LA office',
                    },
                  ],
                  to_port: 9909,
                }, {
                  from_port: 2202,
                  ip_protocol: 'udp',
                  ip_ranges: [
                    {
                      cidr_ip: '10.10.10.20/24',
                      description: 'UDP access from the NY office',

                    },
                  ],
                  to_port: 2202,
                }
                               ],
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

      # Expect that it doesn't try to update security group rules
      authorize_security_group_ingress_request = ec2_client.api_requests.find do |req|
        req[:operation_name] == :authorize_security_group_ingress
      end
      expect(authorize_security_group_ingress_request).to eq(nil)

      revoke_security_group_ingress_request = ec2_client.api_requests.find do |req|
        req[:operation_name] == :revoke_security_group_ingress
      end
      expect(revoke_security_group_ingress_request).to eq(nil)

      authorize_security_group_egress_request = ec2_client.api_requests.find do |req|
        req[:operation_name] == :authorize_security_group_egress
      end
      expect(authorize_security_group_egress_request).to eq(nil)

      revoke_security_group_egress_request = ec2_client.api_requests.find do |req|
        req[:operation_name] == :revoke_security_group_egress
      end
      expect(revoke_security_group_egress_request).to eq(nil)
    }
  end

  # Adds a new ingress rule, leaves one untouched,
  # and removes an existing ingress rule
  # Does the same for egress
  context 'should update ingress/egress rules' do
    recipe do
      aws_security_group 'security_group_name' do
        description 'security_group_description'
        ip_permissions [{
          from_port: 9999,
          ip_protocol: 'tcp',
          ip_ranges: [
            {
              cidr_ip: '10.10.10.10/24',
              description: 'Ingress rule to add',
            },
          ],
          to_port: 9999,
        }, {
          from_port: 22,
          ip_protocol: 'tcp',
          ip_ranges: [
            {
              cidr_ip: '10.10.10.20/24',
              description: 'Ingress rule to stay the same',
            },
          ],
          to_port: 22,
        }
        ]
        ip_permissions_egress [{
          from_port: 8888,
          ip_protocol: 'udp',
          ip_ranges: [
            {
              cidr_ip: '10.10.10.10/24',
              description: 'Egress rule to add',
            },
          ],
          to_port: 8888,
        }, {
          from_port: 22,
          ip_protocol: 'udp',
          ip_ranges: [
            {
              cidr_ip: '10.10.10.20/24',
              description: 'Egress rule to stay the same',

            },
          ],
          to_port: 22,
        }
                              ]
        vpc_id 'vpc-00000000'
        action :create
      end
    end

    it {
      # Mock the ec2 data
      describe_security_groups_stub = ec2_client.stub_data(
        :describe_security_groups,
          security_groups:
              [{
                description: 'security_group_description',
                group_name: 'security_group_name',
                ip_permissions: [{
                  from_port: 1111,
                  ip_protocol: 'tcp',
                  ip_ranges: [
                    {
                      cidr_ip: '10.10.10.10/24',
                      description: 'Ingress rule to remove',
                    },
                  ],
                  to_port: 1111,
                }, {
                  from_port: 22,
                  ip_protocol: 'tcp',
                  ip_ranges: [
                    {
                      cidr_ip: '10.10.10.20/24',
                      description: 'Ingress rule to stay the same',

                    },
                  ],
                  to_port: 22,
                }
                               ],
                owner_id: '333333333333',
                group_id: 'sg-00000000000000000',
                ip_permissions_egress: [{
                  from_port: 2222,
                  ip_protocol: 'udp',
                  ip_ranges: [
                    {
                      cidr_ip: '10.10.10.10/24',
                      description: 'Egress rule to remove',
                    },
                  ],
                  to_port: 2222,
                }, {
                  from_port: 22,
                  ip_protocol: 'udp',
                  ip_ranges: [
                    {
                      cidr_ip: '10.10.10.20/24',
                      description: 'Egress rule to stay the same',

                    },
                  ],
                  to_port: 22,
                }
                               ],
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

      # Expected updates
      authorize_security_group_ingress_request = ec2_client.api_requests.find do |req|
        req[:operation_name] == :authorize_security_group_ingress
      end
      expect(authorize_security_group_ingress_request[:params][:ip_permissions].length).to eq(1)
      expect(authorize_security_group_ingress_request[:params][:ip_permissions][0][:ip_ranges][0][:description]).to eq('Ingress rule to add')

      revoke_security_group_ingress_request = ec2_client.api_requests.find do |req|
        req[:operation_name] == :revoke_security_group_ingress
      end
      expect(revoke_security_group_ingress_request[:params][:ip_permissions].length).to eq(1)
      expect(revoke_security_group_ingress_request[:params][:ip_permissions][0][:ip_ranges][0][:description]).to eq('Ingress rule to remove')

      authorize_security_group_egress_request = ec2_client.api_requests.find do |req|
        req[:operation_name] == :authorize_security_group_egress
      end
      expect(authorize_security_group_egress_request[:params][:ip_permissions].length).to eq(1)
      expect(authorize_security_group_egress_request[:params][:ip_permissions][0][:ip_ranges][0][:description]).to eq('Egress rule to add')

      revoke_security_group_egress_request = ec2_client.api_requests.find do |req|
        req[:operation_name] == :revoke_security_group_egress
      end
      expect(revoke_security_group_egress_request[:params][:ip_permissions].length).to eq(1)
      expect(revoke_security_group_egress_request[:params][:ip_permissions][0][:ip_ranges][0][:description]).to eq('Egress rule to remove')
    }
  end
end
