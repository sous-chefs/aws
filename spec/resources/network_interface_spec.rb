# frozen_string_literal: true

require 'spec_helper'
require 'aws-sdk-ec2'

describe 'aws_network_interface' do
  platform 'ubuntu', '24.04'
  step_into :aws_network_interface

  let(:actions) { :create }
  let(:index) { 1 }
  let(:client) { Aws::EC2::Client.new(region: 'us-east-1', stub_responses: true) }
  let(:available) do
    {
      network_interface_id: 'eni-1234',
      subnet_id: 'subnet-1234',
      status: 'available',
      tag_set: [{ key: 'sous-chefs:aws-network-interface', value: 'app' }],
    }
  end
  let(:attachment) do
    { attachment_id: 'eni-attach-1234', instance_id: 'i-1234', device_index: 1, network_card_index: 0, status: 'attached' }
  end
  let(:attached) { available.merge(status: 'in-use', attachment: attachment) }
  let(:requests) { client.api_requests.map { |request| request.values_at(:operation_name, :params) } }

  before do
    stubbed_client = client
    allow(Aws::EC2::Client).to receive(:new).and_return(stubbed_client)
  end

  let(:chef_run) do
    requested_actions = actions
    target_device = index
    chef_runner.converge_block do
      aws_network_interface 'app' do
        region 'us-east-1'
        subnet_id 'subnet-1234'
        instance_id 'i-1234'
        device_index target_device if target_device
        description 'App secondary interface'
        private_ip_address '10.0.0.15'
        security_groups ['sg-1234']
        action requested_actions
      end
    end
  end

  def describe_interfaces(*states)
    client.stub_responses(:describe_network_interfaces, states.map { |interfaces| { network_interfaces: interfaces } })
  end

  context 'with create followed by attach' do
    let(:actions) { [:create, :attach] }

    it 'plans both actions without mutating EC2 in why-run mode' do
      allow(Chef::Config).to receive(:[]).and_call_original
      allow(Chef::Config).to receive(:[]).with(:why_run).and_return(true)
      describe_interfaces([])

      chef_run

      expect(requests.map(&:first)).to eq([:describe_network_interfaces, :describe_network_interfaces])
    end

    it 'tags at creation, waits for discovery, and attaches at the explicit index' do
      describe_interfaces([], [], [available], [available], [attached])
      client.stub_responses(:create_network_interface, network_interface: available)
      client.stub_responses(:attach_network_interface, attachment_id: 'eni-attach-1234')

      chef_run

      expect(requests.map(&:first)).to eq(%i(describe_network_interfaces create_network_interface describe_network_interfaces describe_network_interfaces describe_network_interfaces attach_network_interface describe_network_interfaces))
      expect(requests[1].last).to include(
        subnet_id: 'subnet-1234',
        description: 'App secondary interface',
        private_ip_address: '10.0.0.15',
        groups: ['sg-1234'],
        tag_specifications: [{ resource_type: 'network-interface', tags: available[:tag_set] }]
      )
      expect(requests[5].last).to eq(network_interface_id: 'eni-1234', instance_id: 'i-1234', device_index: 1)
    end

    it 'only reads when the interface is already attached as requested' do
      describe_interfaces([attached])
      chef_run
      expect(requests.map(&:first)).to eq([:describe_network_interfaces, :describe_network_interfaces])
    end
  end

  it 'refuses an ambiguous identity even when the second match is on a later page' do
    pages = [
      { network_interfaces: [available], next_token: 'next' },
      { network_interfaces: [available.merge(network_interface_id: 'eni-5678')] },
    ]
    client.stub_responses(:describe_network_interfaces, pages)

    expect { chef_run }.to raise_error(Chef::Exceptions::ValidationFailed, /multiple/)
    expect(requests.last.last).to include(next_token: 'next')
    expect(requests.map(&:first).uniq).to eq([:describe_network_interfaces])
  end

  context 'with attach' do
    let(:actions) { :attach }

    it 'refuses an attachment at a different device index' do
      describe_interfaces([attached.merge(attachment: attachment.merge(device_index: 2))])
      expect { chef_run }.to raise_error(Chef::Exceptions::ValidationFailed, /target/)
      expect(requests.map(&:first)).to eq([:describe_network_interfaces])
    end

    it 'requires the target before contacting EC2' do
      allow(self).to receive(:index).and_return(nil)
      expect { chef_run }.to raise_error(Chef::Exceptions::ValidationFailed, /device_index/)
      expect(requests).to be_empty
    end

    it 'resumes an in-progress attach without sending another attach request' do
      describe_interfaces([attached.merge(attachment: attachment.merge(status: 'attaching'))], [attached])
      chef_run
      expect(requests.map(&:first)).to eq([:describe_network_interfaces, :describe_network_interfaces])
    end
  end

  context 'with detach followed by delete' do
    let(:actions) { [:detach, :delete] }

    it 'plans both actions without mutating EC2 in why-run mode' do
      allow(Chef::Config).to receive(:[]).and_call_original
      allow(Chef::Config).to receive(:[]).with(:why_run).and_return(true)
      describe_interfaces([attached])

      chef_run

      expect(requests.map(&:first)).to eq([:describe_network_interfaces, :describe_network_interfaces])
    end

    it 'waits for the interface to become available before deleting it' do
      describe_interfaces([attached], [attached.merge(attachment: attachment.merge(status: 'detaching'))], [available], [available])
      chef_run

      expect(requests.map(&:first)).to eq(%i(describe_network_interfaces detach_network_interface describe_network_interfaces describe_network_interfaces describe_network_interfaces delete_network_interface))
      expect(requests[1].last).to eq(attachment_id: 'eni-attach-1234')
      expect(requests.last.last).to eq(network_interface_id: 'eni-1234')
    end

    it 'resumes an in-progress detach without sending another detach request' do
      describe_interfaces([attached.merge(attachment: attachment.merge(status: 'detaching'))], [available], [available])
      chef_run

      expect(requests.map(&:first)).to eq(%i(describe_network_interfaces describe_network_interfaces describe_network_interfaces delete_network_interface))
    end

    it 'only reads when the interface is already absent' do
      describe_interfaces([])
      chef_run
      expect(requests.map(&:first)).to eq([:describe_network_interfaces, :describe_network_interfaces])
    end

    it 'refuses to detach from another instance and never reaches delete' do
      describe_interfaces([attached.merge(attachment: attachment.merge(instance_id: 'i-5678'))])
      expect { chef_run }.to raise_error(Chef::Exceptions::ValidationFailed, /target/)
      expect(requests.map(&:first)).to eq([:describe_network_interfaces])
    end
  end

  context 'with delete' do
    let(:actions) { :delete }

    it 'refuses to delete an attached interface' do
      describe_interfaces([attached])
      expect { chef_run }.to raise_error(Chef::Exceptions::ValidationFailed, /available/)
      expect(requests.map(&:first)).to eq([:describe_network_interfaces])
    end

    it 'ignores interfaces without the exact ownership tag' do
      describe_interfaces([available.merge(tag_set: [])])
      chef_run
      expect(requests.map(&:first)).to eq([:describe_network_interfaces])
    end
  end
end
