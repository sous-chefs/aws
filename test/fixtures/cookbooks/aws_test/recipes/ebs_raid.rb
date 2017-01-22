apt_update 'update'

aws_ebs_raid 'db_ebs_raid' do
  aws_access_key node['aws_test']['key_id']
  aws_secret_access_key node['aws_test']['access_key']
  disk_size 10
  disk_count 3
  level 5
  mount_point '/aws_raid'
end
