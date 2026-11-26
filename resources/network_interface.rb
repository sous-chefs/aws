# frozen_string_literal: true

provides :aws_network_interface
unified_mode true

use '_partial/_aws_common'

property :subnet_id, String, required: true, regex: /\Asubnet-[0-9a-f]+\z/
property :instance_id, String, regex: /\Ai-[0-9a-f]+\z/
property :device_index, Integer
property :description, String
property :private_ip_address, String
property :security_groups, Array

include AwsCookbook::Ec2

default_action :create

action :create do
  return if managed_interface

  converge_by("create network interface #{new_resource.name} in #{new_resource.subnet_id}") do
    options = {
      subnet_id: new_resource.subnet_id,
      tag_specifications: [{ resource_type: 'network-interface', tags: [ownership_tag] }],
    }
    options[:description] = new_resource.description if new_resource.description
    options[:private_ip_address] = new_resource.private_ip_address if new_resource.private_ip_address
    options[:groups] = new_resource.security_groups if new_resource.security_groups
    id = ec2.create_network_interface(options).network_interface.network_interface_id
    wait_for_interface(id, 'to become available') { |eni| available?(eni) }
  end
end

action :attach do
  validate_target!
  eni = managed_interface
  unless eni
    fail_validation('create the managed interface before attaching it') unless follows_in_why_run?(:create, :attach)

    converge_by("attach network interface #{new_resource.name} to #{new_resource.instance_id} at device #{new_resource.device_index} after creation")
    return
  end

  id = eni.network_interface_id
  if eni.attachment
    validate_attachment!(eni.attachment)
    return if eni.attachment.status == 'attached'

    fail_validation("attachment is #{eni.attachment.status}") unless eni.attachment.status == 'attaching'
  else
    fail_validation("#{id} must be available before attachment") unless available?(eni)
    converge_by("attach network interface #{id} to #{new_resource.instance_id} at device #{new_resource.device_index}") do
      ec2.attach_network_interface(network_interface_id: id, instance_id: new_resource.instance_id, device_index: new_resource.device_index)
    end
  end

  wait_for_interface(id, 'to become attached') do |current|
    validate_attachment!(current.attachment) if current.attachment
    current.attachment&.status == 'attached'
  end
end

action :detach do
  validate_target!
  eni = managed_interface
  return if eni.nil? || available?(eni)

  attachment = eni.attachment
  validate_attachment!(attachment)
  unless %w(detaching detached).include?(attachment.status)
    fail_validation("attachment is #{attachment.status}") unless attachment.status == 'attached'
    fail_validation('attachment ID is missing') if attachment.attachment_id.to_s.empty?

    converge_by("detach network interface #{eni.network_interface_id} from #{new_resource.instance_id}") do
      ec2.detach_network_interface(attachment_id: attachment.attachment_id)
    end
  end

  wait_for_interface(eni.network_interface_id, 'to become available') do |current|
    if current.attachment && current.attachment.attachment_id != attachment.attachment_id
      fail_validation('attachment changed while waiting for detach')
    end
    available?(current)
  end
end

action :delete do
  eni = managed_interface
  return unless eni

  id = eni.network_interface_id
  unless available?(eni) || follows_in_why_run?(:detach, :delete)
    fail_validation("#{id} must be detached and available before deletion")
  end
  converge_by("delete network interface #{id}") do
    ec2.delete_network_interface(network_interface_id: id)
  rescue Aws::EC2::Errors::InvalidNetworkInterfaceIDNotFound
    # EC2 may have removed the interface since the describe call.
  end
end

action_class do
  include AwsCookbook::Ec2

  def ownership_tag
    { key: 'sous-chefs:aws-network-interface', value: new_resource.name }
  end

  def managed_interface
    tag = ownership_tag
    unless tag[:value].match?(/\A[a-zA-Z0-9_.:-]{1,256}\z/)
      fail_validation('the name must contain 1–256 letters, digits, dots, underscores, colons or hyphens')
    end

    matches = ec2.describe_network_interfaces(
      filters: [
        { name: 'subnet-id', values: [new_resource.subnet_id] },
        { name: "tag:#{tag[:key]}", values: [tag[:value]] },
      ],
      max_results: 100
    ).each_page.flat_map(&:network_interfaces).select do |eni|
      eni.subnet_id == new_resource.subnet_id &&
        eni.tag_set.any? { |entry| entry.key == tag[:key] && entry.value == tag[:value] }
    end
    fail_validation('multiple network interfaces have this ownership tag in the subnet') if matches.size > 1

    eni = matches.first
    fail_validation('the matching interface is requester-managed') if eni&.requester_managed
    eni
  end

  def validate_target!
    fail_validation('instance_id and a positive device_index are required') unless new_resource.instance_id && new_resource.device_index.to_i.positive?
  end

  def validate_attachment!(attachment)
    unless attachment && attachment.instance_id == new_resource.instance_id &&
           attachment.device_index == new_resource.device_index && (attachment.network_card_index || 0).zero?
      fail_validation('the attachment does not match the requested instance and device target on network card 0')
    end
  end

  def available?(eni)
    eni.status == 'available' && eni.attachment.nil?
  end

  def follows_in_why_run?(prerequisite, action)
    whyrun_mode? && new_resource.action.take_while { |planned| planned != action }.include?(prerequisite)
  end

  def wait_for_interface(id, expected_state)
    return if whyrun_mode?

    ready = 15.times.any? do |attempt|
      sleep 2 unless attempt.zero?
      eni = managed_interface
      eni && eni.network_interface_id == id && yield(eni)
    end
    fail_validation("timed out waiting for #{id} #{expected_state}") unless ready
  end

  def fail_validation(message)
    raise Chef::Exceptions::ValidationFailed, "#{new_resource}: #{message}"
  end
end
