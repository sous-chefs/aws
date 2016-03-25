aws_ebs_volume 'db_ebs_volume' do
  aws_access_key node['aws_test']['key_id']
  aws_secret_access_key node['aws_test']['access_key']
  size 1
  device '/dev/sdi'
  delete_on_termination true
  action [:create, :attach]
end

aws_ebs_volume 'db_ebs_volume' do
  action [:detach]
end

aws_ebs_volume 'db_ebs_volume' do
  action [:delete]
end
