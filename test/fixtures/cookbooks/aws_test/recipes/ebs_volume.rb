include_recipe 'aws'

aws_ebs_volume 'db_ebs_volume' do
  aws_access_key node['aws_test']['key_id']
  aws_secret_access_key node['aws_test']['access_key']
  size 50
  device '/dev/sdi'
  action [:create, :attach]
end
