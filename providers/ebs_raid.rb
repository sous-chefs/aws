include Opscode::Aws::Ec2

action :auto_attach do

  package "mdadm" do
    action :install
  end

  if @new_resource.encrypted
    package "cryptsetup" do
      action :install
    end
  end

  # Baseline expectations.
  node.set['aws'] ||= {}
  node.set[:aws][:raid] ||= {}

  # Mount point information.
  node.set[:aws][:raid][@new_resource.mount_point] ||= {}

  # Encryption information
  node.set[:aws][:raid][:encrypted] ||= {}

  # we're done we successfully located what we needed
  if !already_mounted(@new_resource.mount_point, @new_resource.encrypted, @new_resource.dm_name) && !locate_and_mount(@new_resource.mount_point, @new_resource.mount_point_owner,
                                                                                                                      @new_resource.mount_point_group, @new_resource.mount_point_mode,
                                                                                                                      @new_resource.filesystem, @new_resource.filesystem_options,
                                                                                                                      @new_resource.encrypted, @new_resource.encryption_passwd,
                                                                                                                      @new_resource.dm_name)

    # If we get here, we couldn't auto attach, nor re-allocate an existing set of disks to ourselves.  Auto create the md devices

    # Stopping udev to ensure RAID md device allocates md0 properly
    manage_udev("stop")

    create_raid_disks(@new_resource.mount_point,
                      @new_resource.mount_point_owner,
                      @new_resource.mount_point_group,
                      @new_resource.mount_point_mode,
                      @new_resource.disk_count,
                      @new_resource.disk_size,
                      @new_resource.level,
                      @new_resource.filesystem,
                      @new_resource.filesystem_options,
                      @new_resource.snapshots,
                      @new_resource.disk_type,
                      @new_resource.disk_piops,
                      @new_resource.encrypted,
                      @new_resource.encryption_passwd,
                      @new_resource.dm_name)

    @new_resource.updated_by_last_action(true)
  end
end

private

# AWS's volume attachment interface assumes that we're using
# sdX style device names.  The ones we actually get will be xvdX
def find_free_volume_device_prefix
  # Specific to ubuntu 11./12.
  vol_dev = "sdh"

  begin
    vol_dev = vol_dev.next
    base_device = "/dev/#{vol_dev}1"
    Chef::Log.info("dev pre trim #{base_device}")
  end while ::File.exists?(base_device)

  vol_dev
end

def find_free_dm_device
  number=0
  begin
    dir = "/dev/dm-#{number}"
    number +=1
  end while ::File.exists?(dir)

  dir[5, dir.length]
end

def find_free_md_device_name
  number=0
  #TODO, this won't work with more than 10 md devices
  begin
    dir = "/dev/md#{number}"
    Chef::Log.info("md pre trim #{dir}")
    number +=1
  end while ::File.exists?(dir)

  dir[5, dir.length]
end

def verify_dm_device_from_mp(mount_point, dm_name)
  devices = {}
  Dir.glob("/dev/dm-[0-9]*").each do |dir|
    # First we check that the private crypsetup device lstat matches our mount point
    if ::File.lstat(dir).rdev == ::File.lstat(mount_point).dev
      devices['dm'] = dir.gsub("\n","")

      Chef::Log.info("Verified #{devices['dm']} lstat link to #{mount_point}")

      # Next we sanity check the md device of what crypsetup is using
      md = `cryptsetup status #{dm_name}|grep device|awk '{print $2}'`
      devices['md'] = md.gsub("\n", "")

      Chef::Log.info("Verified /dev/mapper/#{dm_name} crypsetup relationship to #{devices['md']}")
      return devices
      break
    end
  end
end

def verify_md_device_from_mp(mount_point)
  device = {}
  Dir.glob("/dev/md[0-9]*").each do |dir|
    # Look at the mount point directory and see if containing device
    # is the same as the md device by comparing lstat ID's.
    if ::File.lstat(dir).rdev == ::File.lstat(mount_point).dev
      device['md'] = dir.gsub("\n", "")
      Chef::Log.info("Verified #{device['md']} linked to #{mount_point}") unless device.nil?
      break
    end
  end
  device
end

def update_node_from_md_device(md_device, mount_point)
  command = "mdadm --misc -D #{md_device} | grep '/dev/s\\|/xv' | awk '{print $7}' | tr '\\n' ' '"
  Chef::Log.info("Running #{command}")
  raid_devices = `#{command}`
  Chef::Log.info("already found the mounted device, created from #{raid_devices}")

  Chef::Log.info("Updating node attributes for md device '#{md_device}' and disks '#{raid_devices}'")
  node.set[:aws][:raid][mount_point][:raid_dev] = md_device.sub(/\/dev\//,"")
  node.set[:aws][:raid][mount_point][:devices] = raid_devices
  node.save
end

def already_mounted(mount_point, encrypted, dm_name)
  if !::File.exists?(mount_point)
    return false
  end

  if encrypted
    dm = verify_dm_device_from_mp(mount_point, dm_name)
    if dm.empty? || ! dm.has_key?('dm') || dm['dm'].nil? || ! dm.has_key?('md') || dm['md'].empty?
      Chef::Log.info("Could not map a working md or device mapper to the mount point: #{mount_point}")
      return false
    end

    node.set[:aws][:raid][:encrypted][:dm_device] = dm['dm'].sub(/\/dev\//,"")
    Chef::Log.info("Updating node attribute dm_device to #{dm['dm']}")

    update_node_from_md_device(dm['md'], mount_point)

  else
    devices = verify_md_device_from_mp(mount_point)

    if devices.empty? || ! devices.has_key?('md') || devices['md'].empty?
      Chef::Log.info("Could not map a working device from the mount point: #{mount_point}")
      return false
    end

    update_node_from_md_device(devices['md'], mount_point)
  end

  return true
end

private
def udev(cmd, log)
  execute log do
    Chef::Log.debug(log)
    command "udevadm control #{cmd}"
  end
end

def update_initramfs()
  execute "updating initramfs" do
    Chef::Log.debug("updating initramfs to ensure RAID config persists reboots")
    command "update-initramfs -u"
  end
end

def manage_udev(action)
  if action == "stop"
    udev("--stop-exec-queue", "stopping udev...")
  elsif action == "start"
    udev("--start-exec-queue", "starting udev queued events..")
  else
   Chef::Log.fatal("Incorrect action passed to manage_udev")
  end
end

# Attempt to find an unused data bag and mount all the EBS volumes to our system
# Note: recovery from this assumed state is weakly untested.
def locate_and_mount(mount_point, mount_point_owner, mount_point_group,
                     mount_point_mode, filesystem, filesystem_options,
                     encrypted, encryption_passwd, dm_name)

  if node['aws'].nil? || node['aws']['raid'].nil? || node['aws']['raid'][mount_point].nil?
    Chef::Log.info("No mount point found '#{mount_point}' for node")
    return false
  end

  if encrypted
    if node['aws']['raid']['encrypted']['dm_device'].nil? || node['aws']['raid'][mount_point]['raid_dev'].nil? || node['aws']['raid'][mount_point]['device_map'].nil?

      Chef::Log.info("No dm mapper or RAID device found for encrypted mount point /dev/mapper/#{dm_name} for node")
      return false
    end
  else
    if node['aws']['raid'][mount_point]['raid_dev'].nil? || node['aws']['raid'][mount_point]['device_map'].nil?
      Chef::Log.info("No raid device found for mount point '#{mount_point}' for node")
      return false
    end
  end

  raid_dev = node['aws']['raid'][mount_point]['raid_dev']
  devices_string = device_map_to_string(node['aws']['raid'][mount_point]['device_map'])

  # Stop udev
  manage_udev("stop")

  # Mount volumes
  mount_volumes(node['aws']['raid'][mount_point]['device_map'])

  # Assemble raid device.
  assemble_raid(raid_dev, devices_string)

  if encrypted
    dm_device = node['aws']['raid']['encrypted']['dm_device']
    dm_name = node['aws']['raid']['encrypted']['dm_name']

    Chef::Log.info("Encrypted raid. Mapping #{dm_device} to RAID device #{raid_dev}.")
    Chef::Log.info("dm-crypt mapping /dev/mapper/#{dm_name} to mount point #{mount_point}")

    execute "unlocking encrypted partition" do
      command "echo '#{encryption_passwd}' | cryptsetup -q luksOpen /dev/#{raid_dev} #{dm_name} --key-file=-"
    end
  else
    Chef::Log.info("Raid device is #{raid_dev} and mount path is #{mount_point}")
  end

  # Now mount the drive
  mount_device(raid_dev, mount_point, mount_point_owner, mount_point_group,
               mount_point_mode, filesystem, filesystem_options,
               encrypted, dm_name)

  # update initramfs to ensure RAID config persists reboots
  update_initramfs()

  # Start udev back up
  manage_udev("start")

  true
end

# TODO fix this kludge: ideally we'd pull in the device information from the ebs_volume
#   resource but it's not up-to-date at this time without breaking this action up.
def correct_device_map(device_map)
  corrected_device_map = {}
  # Rekey
  device_map.keys.each do |k|
    if k.start_with?('sd')
      new_k = 'xvd' + k[2..-1]
      if corrected_device_map.include?(new_k)
        Chef::Log.error("Unable to remap due to collision.")
        return {}
      end
      corrected_device_map[new_k] = device_map[k]
    else
      corrected_device_map[k] = device_map[k]
    end
  end
  corrected_device_map
end

# Generate the string using the corrected map.
def device_map_to_string(device_map)
  corrected_map = correct_device_map(device_map)

  devices_string = ""
  corrected_map.keys.sort.each do |k|
    devices_string += "/dev/#{k} "
  end
  devices_string
end

def mount_volumes(device_vol_map)
  # Attach the volumes
  device_vol_map.keys.sort.each do |dev_device|
    attach_volume(dev_device, device_vol_map[dev_device])
  end

  # Wait until all volumes are mounted
  ruby_block "wait_#{new_resource.name}" do
    block do
      count = 0
      begin
        Chef::Log.info("sleeping 10 seconds until EBS volumes have re-attached")
        sleep 10
        count += 1
      end while !device_vol_map.all? {|dev_path| ::File.exists?(dev_path) }

      # Accounting to see how often this code actually gets used.
      node.set[:aws][:raid][mount_point][:device_attach_delay] = count * 10
    end
  end
end

# Assembles the raid if it doesn't already exist
# Note: raid_dev is the "suggested" location.  mdadm may actually put it somewhere else.
def assemble_raid(raid_dev, devices_string)
  if ::File.exists?(raid_dev)
    Chef::Log.info("Device #{raid_dev} exists skipping")
    return
  end

  Chef::Log.info("Raid device #{raid_dev} does not exist re-assembling")
  Chef::Log.debug("Devices for #{raid_dev} are #{devices_string}")

  # Now that attach is done we re-build the md device
  # We have to grab the UUID of the md device or the disks will be assembled with the UUID stored
  # within the superblock metadata, causing the md_device number to be randomly
  # chosen if restore is happening on a different host
  execute "re-attaching raid device" do
    command "mdadm -A --uuid=`mdadm -E --scan|awk '{print $4}'|sed 's/UUID=//g'` #{raid_dev} #{devices_string}"
    # mdadm may return 2 but still return a clean raid device.
    returns [0, 2]
  end
end

def mount_device(raid_dev, mount_point, mount_point_owner, mount_point_group,
                 mount_point_mode, filesystem, filesystem_options,
                 encrypted, dm_name)

  # Create the mount point
  directory mount_point do
    owner mount_point_owner
    group mount_point_group
    mode mount_point_mode
    action    :create
    not_if "test -d #{mount_point}"
  end

  # Try to figure out the actual device.
  ruby_block "find md device in #{new_resource.name}" do
    block do
      if ::File.exists?(mount_point)
        Chef::Log.info("Already mounted: #{mount_point}")
      end

      md_device = nil
      Dir.glob("/dev/md[0-9]*").each do |dir|
        Chef::Log.error("More than one /dev/mdX found.") unless md_device.nil?
        md_device = dir
      end

      if encrypted
        Chef::log.fatal("dm_name must exist to mount volumes") if dm_name.nil?
        device = "/dev/mapper/#{dm_name}"
      else
        device = md_device
      end

      Chef::Log.info("Attempting to mount #{mount_point} to #{device}")
      system("mount -t #{filesystem} -o #{filesystem_options} #{device} #{mount_point}")
    end
  end
end

# Attach all existing ami instances if they exist on this node, if not, we want an error to occur  Detects disk from node information
def attach_volume(disk_dev, volume_id)
  disk_dev_path = "/dev/#{disk_dev}"

  aws = data_bag_item(node['aws']['databag_name'], node['aws']['databag_entry'])

  Chef::Log.info("Attaching existing ebs volume id #{volume_id} for device #{disk_dev_path}")

  aws_ebs_volume disk_dev_path do
    aws_access_key          aws['aws_access_key_id']
    aws_secret_access_key   aws['aws_secret_access_key']
    device                  disk_dev_path
    name                    disk_dev
    volume_id               volume_id
    action                  [:attach]
    provider                "aws_ebs_volume"
  end
end

# Mount point for where to mount I.E /mnt/filesystem
# Diskset      I.E sdi (which creates sdi1-sdi<n>
# Raid size.   The total size of the array
# Raid level.  The raid level to use.
# Filesystem.  The file system to create.
# Filesystem_options The options to pass to mount
# Snapshots.   The list of snapshots to create the ebs volumes from.
#              If it's not nil, must have exactly <num_disks> elements

def create_raid_disks(mount_point, mount_point_owner, mount_point_group, mount_point_mode,
                      num_disks, disk_size, level, filesystem, filesystem_options,
                      snapshots, disk_type, disk_piops, encrypted, encryption_passwd, dm_name)

  creating_from_snapshot = !(snapshots.nil? || snapshots.size == 0)

  disk_dev = find_free_volume_device_prefix
  Chef::Log.debug("vol device prefix is #{disk_dev}")

  raid_dev = find_free_md_device_name
  Chef::Log.debug("target raid device is /dev/#{raid_dev}")

  if encrypted
    dm_device = find_free_dm_device
    Chef::Log.info("Device mapper is /dev/#{dm_device}")
  end

  devices = {}

  # For each volume add information to the mount metadata
  (1..num_disks).each do |i|

    disk_dev_path = "#{disk_dev}#{i}"

    aws = data_bag_item(node['aws']['databag_name'], node['aws']['databag_entry'])

    Chef::Log.info "Snapshot array is #{snapshots[i-1]}"
    aws_ebs_volume disk_dev_path do
      aws_access_key          aws['aws_access_key_id']
      aws_secret_access_key   aws['aws_secret_access_key']
      size                    disk_size
      volume_type             disk_type
      piops                   disk_piops
      device                  "/dev/#{disk_dev_path}"
      name                    disk_dev_path
      action                  [:create, :attach]
      snapshot_id             creating_from_snapshot ? snapshots[i-1] : ""
      provider                "aws_ebs_volume"

      # set up our data bag info
      devices[disk_dev_path] = "pending"

      Chef::Log.info("creating ebs volume for device #{disk_dev_path} with size #{disk_size}")
    end

    Chef::Log.info("attach dev: #{disk_dev_path}")
  end

  ruby_block "sleeping_#{new_resource.name}" do
    block do
      Chef::Log.debug("sleeping 10 seconds to let drives attach")
      sleep 10
    end
  end

  # Create the raid device strings w/sd => xvd correction
  devices_string = device_map_to_string(devices)
  Chef::Log.info("finished sorting devices #{devices_string}")

  if not creating_from_snapshot
    # Create the raid device on our system
    execute "creating raid device" do
      Chef::Log.info("creating raid device /dev/#{raid_dev} with raid devices #{devices_string}")
      command "mdadm --create /dev/#{raid_dev} --level=#{level} --raid-devices=#{devices.size} #{devices_string}"
    end

    if encrypted
      execute "creating luks encrypted partition" do
        command "echo '#{encryption_passwd}' | cryptsetup -v -q luksFormat /dev/#{raid_dev} --key-file=-"
      end

      execute "unlocking encrypted partition" do
        command "echo '#{encryption_passwd}' | cryptsetup -q luksOpen /dev/#{raid_dev} #{dm_name} --key-file=-"
      end
    end

    # NOTE: must be a better way.
    # Try to figure out the actual device.
    ruby_block "formatting md device in #{new_resource.name}" do
      block do
        if encrypted
          device = "/dev/mapper/#{dm_name}"
        else
          device = nil
          Dir.glob("/dev/md[0-9]*").each do |dir|
            Chef::Log.error("More than one /dev/mdX found.") unless device.nil?
            device = dir
          end
        end

        Chef::Log.info("Format device found: #{device}")
        case filesystem
          when "ext4"
            system("mke2fs -t #{filesystem} -F #{device}")
          else
            #TODO fill in details on how to format other filesystems here
            Chef::Log.info("Can't format filesystem #{filesystem}")
        end
      end
    end
  else
    # Reassembling the raid device on our system
    assemble_raid("/dev/#{raid_dev}", devices_string)

    if encrypted
      execute "unlocking encrypted partition" do
        command "echo '#{encryption_passwd}' | cryptsetup -q luksOpen /dev/#{raid_dev} #{dm_name} --key-file=-"
      end
    end
  end

  # start udev
  manage_udev("start")

  # Mount the device
  mount_device(raid_dev, mount_point, mount_point_owner, mount_point_group,
               mount_point_mode, filesystem, filesystem_options,
               encrypted, dm_name)

  # update initramfs to ensure RAID config persists reboots
  update_initramfs()

  # Not invoked until the volumes have been successfully created and attached
  ruby_block "databagupdate" do
    block do
      Chef::Log.info("finished creating disks")

      devices.each_pair do |key, value|
        value = node['aws']['ebs_volume'][key]['volume_id']
        devices[key] =  value
        Chef::Log.info("value is #{value}")
      end

      # Assemble all the data bag meta data
      node.set[:aws][:raid][mount_point][:raid_dev] = raid_dev
      node.set[:aws][:raid][mount_point][:device_map] = devices
      node.save

      if encrypted
        node.set[:aws][:raid][:encrypted][:dm_device] = dm_device
        node.set[:aws][:raid][:encrypted][:dm_name] = dm_name
        node.save
      end

    end
  end
end
