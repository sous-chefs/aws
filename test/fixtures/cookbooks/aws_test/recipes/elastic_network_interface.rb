aws_elastic_network_interface 'elastic_network_interface' do
  aws_access_key node['aws_test']['key_id']
  aws_secret_access_key node['aws_test']['access_key']
  network_interface_id node['aws_test']['elastic_network_interface_id']
  device_index node['aws_test']['elastic_network_interface_device_index'].to_s
  action :attach
end

aws_elastic_ip 'elastic_ip' do
  aws_access_key node['aws_test']['key_id']
  aws_secret_access_key node['aws_test']['access_key']
  ip node['aws_test']['elastic_ip']
  network_interface_id node['aws_test']['elastic_network_interface_id']
  action :associate
end
