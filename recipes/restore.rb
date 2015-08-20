include_recipe 'aws'

directory "/mnt/test" do
  action :create
  owner 'root'
  group 'root'
  mode '0775'
end


aws_ebs_volume "/var/www-volume" do
  device '/dev/xvdf'
  description 'volume restore from snapshot test'
  search_tags [{name: 'tag:Environment', values:['dev']},
                {name: 'tag:Contents', values:['www']},
                {name: 'tag:Projects', values: ['buyerquest.net']}]
  most_recent_snapshot true
  require_existing_snapshot false
  override_existing_volume false
  attach_existing true
  action [:create, :attach]
end

# After creating the volume, we need to apply tags to the volume
# in order to easily snapshot only that volume in the future.
resource_tag node['aws']['ebs_volume']["/mnt/test-volume"]['volume_id'] do
  action :add
  tags({"Environment" => "dev", "Contents" => "www", "Project" => "buyerquest.net", "Name" => "/var/www"})
end

# Need to check if the volume is formatted, in case it was created as new; if it was created as new, then
# we need to format, otherwise we don't want to format.
execute "format-www-volume" do
  command "sudo mkfs.xfs /dev/xvdf"
  action :run
  not_if "blkid -o value -s TYPE /dev/xvdj && blkid -o value -s TYPE /dev/xvdj | egrep '(xfs|ext3|ext4)'"
end


mount "/var/www" do
  device "/dev/xvdf"
  fstype "xfs"
  action :mount
  not_if "mount | grep '/var/www'"
end
