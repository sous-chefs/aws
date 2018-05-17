property :region,                String, default: lazy { fallback_region }
property :size,                  Integer
property :snapshot_id,           String
property :most_recent_snapshot,  [true, false], default: false
property :availability_zone,     String
property :device,                String
property :volume_id,             String
property :description,           String
property :timeout,               default: 3 * 60 # 3 mins, nil or 0 for no timeout
property :snapshots_to_keep,     default: 2
property :volume_type,           String
property :piops,                 Integer, default: 0
property :encrypted,             [true, false], default: false
property :kms_key_id,            String
property :delete_on_termination, [true, false], default: false
property :tags,                  Hash, default: {}

# authentication
property :aws_access_key,        String
property :aws_secret_access_key, String
property :aws_session_token,     String
property :aws_assume_role_arn,   String
property :aws_role_session_name, String

include AwsCookbook::Ec2 # needed for aws_region helper

action :create do
  raise 'Cannot create a volume with a specific volume_id as AWS chooses volume ids. The volume_id property can only be used with the :attach action.' if new_resource.volume_id

  # fetch volume data from node
  nvid = volume_id_in_node_data
  if nvid
    # volume id is registered in the node data, so check that the volume in fact exists in EC2
    vol = volume_by_id(nvid)
    exists = vol && vol[:state] != 'deleting'
    # TODO: determine whether this should be an error or just cause a new volume to be created. Currently erring on the side of failing loudly
    raise "Volume with id #{nvid} is registered with the node but does not exist in EC2. To clear this error, remove the ['aws']['ebs_volume']['#{new_resource.name}']['volume_id'] entry from this node's data." unless exists
  else
    # Determine if there is a volume that meets the resource's specifications and is attached to the current
    # instance in case a previous [:create, :attach] run created and attached a volume but for some reason was
    # not registered in the node data (e.g. an exception is thrown after the attach_volume request was accepted
    # by EC2, causing the node data to not be stored on the server)
    if new_resource.device && (attached_volume = currently_attached_volume(instance_id, new_resource.device)) # rubocop: disable Style/IfInsideElse
      Chef::Log.debug("There is already a volume attached at device #{new_resource.device}")
      compatible = volume_compatible_with_resource_definition?(attached_volume)
      raise "Volume #{attached_volume.volume_id} attached at #{attached_volume.attachments[0].device} but does not conform to this resource's specifications" unless compatible
      Chef::Log.debug("The volume matches the resource's definition, so the volume is assumed to be already created")
      converge_by("update the node data with volume id: #{attached_volume.volume_id}") do
        node.normal['aws']['ebs_volume'][new_resource.name]['volume_id'] = attached_volume.volume_id
        node.save # ~FC075
      end
    else
      # If not, create volume and register its id in the node data
      converge_message = "create a #{new_resource.size}GB volume in #{new_resource.region} "
      converge_message += "using snapshot #{true_snapshot_id} " if true_snapshot_id
      converge_message += "and update the node data with created volume's id"
      converge_by(converge_message) do
        nvid = create_volume(true_snapshot_id,
                             new_resource.size,
                             new_resource.availability_zone,
                             new_resource.timeout,
                             new_resource.volume_type,
                             new_resource.piops,
                             new_resource.encrypted,
                             new_resource.kms_key_id)
        add_tags(nvid)
        node.normal['aws']['ebs_volume'][new_resource.name]['volume_id'] = nvid
        node.save # ~FC075
      end
    end
  end
end

action :attach do
  # determine_volume returns a Hash, not a Mash, and the keys are
  # symbols, not strings.
  vol = determine_volume

  if vol[:state] == 'in-use'
    Chef::Log.info("Vol: #{vol}")
    vol[:attachments].each do |attachment|
      if attachment[:instance_id] != instance_id
        raise "Volume with id #{vol[:volume_id]} exists but is attached to instance #{attachment[:instance_id]}"
      else
        Chef::Log.debug('Volume is already attached')
      end
    end
  else
    converge_by("attach the volume #{vol[:volume_id]} to instance #{instance_id} as #{new_resource.device} and update the node data with created volume's id") do
      # attach the volume and register its id in the node data
      attach_volume(vol[:volume_id], instance_id, new_resource.device, new_resource.timeout)
      mark_delete_on_termination(new_resource.device, vol[:volume_id], instance_id) if new_resource.delete_on_termination
      # always use a symbol here, it is a Hash
      node.normal['aws']['ebs_volume'][new_resource.name]['volume_id'] = vol[:volume_id]
      node.save # ~FC075
    end
  end
end

action :detach do
  vol = determine_volume
  converge_by("detach volume with id: #{vol[:volume_id]}") do
    detach_volume(vol[:volume_id], new_resource.timeout)
  end
end

action :delete do
  vol = determine_volume
  converge_by("delete volume with id: #{vol[:volume_id]}") do
    delete_volume(vol[:volume_id], new_resource.timeout)
  end
end

action :snapshot do
  vol = determine_volume
  converge_by("create a snapshot for volume: #{vol[:volume_id]}") do
    snapshot = ec2.create_snapshot(volume_id: vol[:volume_id], description: new_resource.description)
    add_tags(snapshot[:volume_id])
    Chef::Log.info("Created snapshot of #{vol[:volume_id]} as #{snapshot[:volume_id]}")
  end
end

action :prune do
  vol = determine_volume
  old_snapshots = []
  Chef::Log.info 'Checking for old snapshots'
  ec2.describe_snapshots[:snapshots].sort { |a, b| b[:start_time] <=> a[:start_time] }.each do |snapshot|
    if snapshot[:volume_id] == vol[:volume_id]
      Chef::Log.info "Found old snapshot #{snapshot[:volume_id]} (#{snapshot[:volume_id]}) #{snapshot[:start_time]}"
      old_snapshots << snapshot
    end
  end
  if old_snapshots.length > new_resource.snapshots_to_keep
    old_snapshots[new_resource.snapshots_to_keep, old_snapshots.length].each do |die|
      converge_by("delete snapshot with id: #{die[:snapshot_id]}") do
        Chef::Log.info "Deleting old snapshot #{die[:snapshot_id]}"
        ec2.delete_snapshot(snapshot_id: die[:snapshot_id])
      end
    end
  end
end

action_class do
  include AwsCookbook::Ec2

  def volume_id_in_node_data
    node['aws']['ebs_volume'][new_resource.name]['volume_id']
  rescue NoMethodError
    nil
  end

  # Pulls the volume id from the volume_id attribute or the node data and verifies that the volume actually exists
  def determine_volume
    raise "Cannot proceed unless the 'device' property is defined in the ebs_volume resource!" unless new_resource.device

    vol = currently_attached_volume(instance_id, new_resource.device)
    vol_id = new_resource.volume_id || volume_id_in_node_data || (vol ? vol[:volume_id] : nil)
    raise 'volume_id attribute not set and no volume id is set in the node data for this resource (which is populated by action :create) and no volume is attached at the device' unless vol_id

    # check that volume exists
    vol = volume_by_id(vol_id)
    raise "No volume with id #{vol_id} exists" unless vol

    vol
  end

  # Retrieves information for a volume
  def volume_by_id(volume_id)
    ec2.describe_volumes(volume_ids: [volume_id]).volumes[0]
  end

  # Returns the volume that's attached to the instance at the given device or nil if none matches
  def currently_attached_volume(instance_id, device)
    ec2.describe_volumes(
      filters: [
        { name: 'attachment.device', values: [device] },
        { name: 'attachment.instance-id', values: [instance_id] },
      ]
    ).volumes[0]
  end

  # Returns true if the given volume meets the resource's attributes
  def volume_compatible_with_resource_definition?(volume)
    (new_resource.size.nil? || new_resource.size == volume.size) &&
      (new_resource.availability_zone.nil? || new_resource.availability_zone == volume.availability_zone) &&
      (true_snapshot_id.nil? || true_snapshot_id == volume.snapshot_id)
  end

  # Creates a volume according to specifications and blocks until done (or times out)
  def create_volume(snapshot_id, size, availability_zone, timeout, volume_type, piops, encrypted, kms_key_id)
    availability_zone ||= node['ec2']['placement_availability_zone']

    # Sanity checks so we don't shoot ourselves.
    raise "Invalid volume type: #{volume_type}" if volume_type && !%w(standard io1 gp2 sc1 st1).include?(volume_type)

    params = { availability_zone: availability_zone, encrypted: encrypted, kms_key_id: kms_key_id }
    params['volume_type'] = volume_type if volume_type

    # PIOPs requested. Must specify an iops param and probably won't be "low".
    if volume_type == 'io1'
      raise 'IOPS value not specified.' unless piops >= 100
      params[:iops] = piops
    end

    # Shouldn't see non-zero piops param without appropriate type.
    if piops > 0
      raise 'IOPS param without piops volume type.' unless volume_type == 'io1'
    end

    params[:snapshot_id] = snapshot_id if snapshot_id
    params[:size] = size if size

    nv = ec2.create_volume(params)
    Chef::Log.debug("Created new #{nv[:encrypted] ? 'encryped' : ''} volume #{nv[:volume_id]}#{snapshot_id ? " based on #{snapshot_id}" : ''}")

    # block until created
    begin
      Timeout.timeout(timeout) do
        loop do
          vol = volume_by_id(nv[:volume_id])
          if vol
            if ['in-use', 'available'].include?(vol[:state])
              Chef::Log.info("Volume #{nv[:volume_id]} is available")
              break
            else
              Chef::Log.debug("Volume is #{vol[:state]}")
            end
          end
          sleep 3
        end
      end
    rescue Timeout::Error
      raise "Timed out waiting for volume creation after #{timeout} seconds"
    end

    nv[:volume_id]
  end

  # Attaches the volume and blocks until done (or times out)
  def attach_volume(volume_id, instance_id, device, timeout)
    Chef::Log.debug("Attaching #{volume_id} as #{device}")
    ec2.attach_volume(volume_id: volume_id, instance_id: instance_id, device: device)

    # block until attached
    begin
      Timeout.timeout(timeout) do
        loop do
          vol = volume_by_id(volume_id)
          if vol
            attachment = vol[:attachments].find { |a| a[:state] == 'attached' }
            if !attachment.nil?
              if attachment[:instance_id] == instance_id
                Chef::Log.info("Volume #{volume_id} is attached to #{instance_id}")
                reload_ohai
                break
              else
                raise "Volume is attached to instance #{vol[:aws_instance_id]} instead of #{instance_id}"
              end
            else
              Chef::Log.debug("Volume is #{vol[:state]}")
            end
          end
          sleep 3
        end
      end
    rescue Timeout::Error
      raise "Timed out waiting for volume attachment after #{timeout} seconds"
    end
  end

  # Detaches the volume and blocks until done (or times out)
  def detach_volume(volume_id, timeout)
    vol = volume_by_id(volume_id)
    attachment = vol[:attachments].find { |a| a[:instance_id] == instance_id }
    if attachment.nil?
      attached_instance_ids = vol[:attachments].collect { |a| a[:instance_id] }
      Chef::Log.debug("EBS Volume #{volume_id} is not attached to this instance (attached to #{attached_instance_ids}). Skipping...")
      return
    end
    Chef::Log.debug("Detaching #{volume_id}")
    orig_instance_id = attachment[:instance_id]
    ec2.detach_volume(volume_id: volume_id)

    # block until detached
    begin
      Timeout.timeout(timeout) do
        loop do
          vol = volume_by_id(volume_id)
          if vol && vol[:state] != 'deleting'
            poll_attachment = vol[:attachments].find { |a| a[:instance_id] == instance_id }
            if poll_attachment.nil?
              Chef::Log.info("Volume detached from #{orig_instance_id}")
              reload_ohai
              break
            else
              Chef::Log.debug("Volume: #{vol.inspect}")
            end
          else
            Chef::Log.debug("Volume #{volume_id} no longer exists")
            reload_ohai
            break
          end
          sleep 3
        end
      end
    rescue Timeout::Error
      raise "Timed out waiting for volume detachment after #{timeout} seconds"
    end
  end

  # Deletes the volume and blocks until done (or times out)
  def delete_volume(volume_id, timeout)
    vol = volume_by_id(volume_id)
    raise "Cannot delete volume #{volume_id} as it is currently attached to #{vol[:attachments].size} node(s)" unless vol[:attachments].empty?

    Chef::Log.debug("Deleting #{volume_id}")
    ec2.delete_volume(volume_id: volume_id)

    # block until deleted
    begin
      Timeout.timeout(timeout) do
        loop do
          vol = volume_by_id(volume_id)
          if vol[:state] == 'deleting' || vol[:state] == 'deleted'
            Chef::Log.debug("Volume #{volume_id} entered #{vol[:state]} state")
            node.normal['aws']['ebs_volume'][new_resource.name] = {}
            break
          end
          sleep 3
        end
      end
    rescue Timeout::Error
      raise "Timed out waiting for volume to enter after #{timeout} seconds"
    end
  end

  def mark_delete_on_termination(device_name, volume_id, instance_id)
    Chef::Log.debug("Marking volume #{volume_id} with device name #{device_name} attached to instance #{instance_id} #{new_resource.delete_on_termination} for deletion on instance termination")
    ec2.modify_instance_attribute(block_device_mappings: [{ device_name: device_name, ebs: { volume_id: volume_id, delete_on_termination: new_resource.delete_on_termination } }], instance_id: instance_id)
  end

  # the user may have passed a volume and not a snapshot ID so lookup the snapshot ID instead
  def true_snapshot_id
    id = new_resource.snapshot_id
    if new_resource.snapshot_id =~ /vol/
      Chef::Log.debug("It appears the user passed an EBS volume ID for snapshot_id (#{new_resource.snapshot_id}). Lookup up the snapshot ID from this volume ID.")
      id = new_resource.snapshot_id(find_snapshot_id(new_resource.snapshot_id, new_resource.most_recent_snapshot))
      Chef::Log.debug("Found snapshot ID #{id} from the passed volume ID #{new_resource.snapshot_id}")
    end
    id
  end

  # if volumes are added or removed we need to reload ohai data so cookbook authors
  # have accurate volume data
  def reload_ohai
    ohai 'Reload Ohai data for volume change' do
      action :nothing
    end.run_action(:reload)
  end

  def add_tags(resource_id)
    unless new_resource.tags.nil? || new_resource.tags.empty?
      new_resource.tags.each do |k, v|
        Chef::Log.debug("add tag '#{k}' with value '#{v}' on resource #{resource_id}")
        ec2.create_tags(resources: [resource_id], tags: [{ key: k, value: v }])
      end
    end
  end
end
