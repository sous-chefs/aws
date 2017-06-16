aws_ebs_volume 'ssd_ebs_volume' do
  aws_access_key node['aws_test']['key_id']
  aws_secret_access_key node['aws_test']['access_key']
  size 1
  device '/dev/sdi'
  delete_on_termination true
  action [:create, :attach]
  volume_type 'gp2' # test that specifying type works
end

aws_ebs_volume 'standard_ebs_vol' do
  aws_access_key node['aws_test']['key_id']
  aws_secret_access_key node['aws_test']['access_key']
  size 1
  device '/dev/sdj'
  delete_on_termination true
  action [:create, :attach]
end

aws_ebs_volume 'ssd_ebs_volume' do
  aws_access_key node['aws_test']['key_id']
  aws_secret_access_key node['aws_test']['access_key']
  device '/dev/sdi'
  action [:detach]
end

aws_ebs_volume 'ssd_ebs_volume' do
  aws_access_key node['aws_test']['key_id']
  aws_secret_access_key node['aws_test']['access_key']
  action [:delete]
end

aws_ebs_volume 'standard_ebs_vol' do
  aws_access_key node['aws_test']['key_id']
  aws_secret_access_key node['aws_test']['access_key']
  device '/dev/sdj'
  action [:detach]
end

aws_ebs_volume 'standard_ebs_vol' do
  aws_access_key node['aws_test']['key_id']
  aws_secret_access_key node['aws_test']['access_key']
  device '/dev/sdi'
  action [:delete]
end
