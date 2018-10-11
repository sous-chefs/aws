aws_ssm_parameter_store 'testkitchen' do
  description 'testkitchen'
  value 'testkitchen'
  type 'String'
  action :create
  aws_access_key node['aws_test']['key_id']
  aws_secret_access_key node['aws_test']['access_key']
end

aws_ssm_parameter_store '/testkitchen/ClearTextString' do
  description 'Test Kitchen String Parameter'
  value 'Clear Text Test Kitchen'
  type 'String'
  action :create
  aws_access_key node['aws_test']['key_id']
  aws_secret_access_key node['aws_test']['access_key']
end

aws_ssm_parameter_store 'create test kitchen record path1' do
  path '/pathtest/path1'
  description 'path1'
  value 'path1'
  type 'String'
  action :create
  aws_access_key node['aws_test']['key_id']
  aws_secret_access_key node['aws_test']['access_key']
end

aws_ssm_parameter_store 'create test kitchen record path2' do
  path '/pathtest/path2'
  description 'path2'
  value 'path2'
  type 'SecureString'
  action :create
  aws_access_key node['aws_test']['key_id']
  aws_secret_access_key node['aws_test']['access_key']
end

aws_ssm_parameter_store 'create encrypted test kitchen record with default key' do
  path '/testkitchen/EncryptedStringDefaultKey'
  description 'Test Kitchen Encrypted Parameter - Default'
  value 'Encrypted Test Kitchen Default'
  type 'SecureString'
  action :create
  aws_access_key node['aws_test']['key_id']
  aws_secret_access_key node['aws_test']['access_key']
end

# need to figure out how to test this since it depends on a keyid
# aws_ssm_parameter_store "create encrypted test kitchen record" do
# name '/testkitchen/EncryptedStringCustomKey'
# description 'Test Kitchen Encrypted Parameter - Custom'
# value 'Encrypted Test Kitchen Custom'
# type 'SecureString'
# key_id ''
# action :create
# aws_access_key node['aws_test']['key_id']
# aws_secret_access_key node['aws_test']['access_key']
# end

aws_ssm_parameter_store 'getParameters' do
  path ['/testkitchen/ClearTextString', '/testkitchen']
  return_key 'parameter_values'
  action :get_parameters
  aws_access_key node['aws_test']['key_id']
  aws_secret_access_key node['aws_test']['access_key']
end

aws_ssm_parameter_store 'getParametersbypath' do
  path '/pathtest/'
  recursive true
  with_decryption true
  return_key 'path_values'
  action :get_parameters_by_path
  aws_access_key node['aws_test']['key_id']
  aws_secret_access_key node['aws_test']['access_key']
end

file '/tmp/test_params' do
  content(
    lazy { node.run_state['path_values'].inspect }
  )
  action :create
end

ruby_block 'test_params' do
  block do
    Chef::Log.warn Chef::JSONCompat.to_json_pretty(node.run_state['path_values'])
  end
  action :run
end

aws_ssm_parameter_store 'get clear_value' do
  path '/testkitchen/ClearTextString'
  return_key 'clear_value'
  action :get
  aws_access_key node['aws_test']['key_id']
  aws_secret_access_key node['aws_test']['access_key']
end

aws_ssm_parameter_store 'get decrypted_value' do
  path '/testkitchen/EncryptedStringDefaultKey'
  return_key 'decrypted_value'
  with_decryption true
  action :get
  aws_access_key node['aws_test']['key_id']
  aws_secret_access_key node['aws_test']['access_key']
end

# aws_ssm_parameter_store 'get decrypted_custom_value' do
# name '/testkitchen/EncryptedStringCustomKey'
# return_key 'decrypted_custom_value'
# with_decryption true
# action :get
# aws_access_key node['aws_test']['key_id']
# aws_secret_access_key node['aws_test']['access_key']
# end

# file '/tmp/file_with_data.txt' do
#   sensitive
#   content <<-EOF
#   EOF
#   action :create
# end

file '/tmp/ssm_parameters.json' do
  content lazy {
    Chef::JSONCompat.to_json_pretty(
      clear_value: node.run_state['clear_value'],
      #:decrypted_custom_value => node.run_state['decrypted_custom_value'],
      decrypted_value: node.run_state['decrypted_value'],
      path1_value: node.run_state['path_values']['/pathtest/path1'],
      path2_value: node.run_state['path_values']['/pathtest/path2'],
      parm1_value: node.run_state['parameter_values']['/testkitchen/ClearTextString'],
      parm2_value: node.run_state['parameter_values']['/testkitchen']
    )
  }
  action :create
end

aws_ssm_parameter_store 'create test kitchen record' do
  path '/testkitchen/ClearTextString'
  description 'NewString'
  value 'NewString'
  type 'String'
  overwrite true
  action :create
  aws_access_key node['aws_test']['key_id']
  aws_secret_access_key node['aws_test']['access_key']
end

# Delete Test Keys
%w(testkitchen /pathtest/path1 /pathtest/path2).each do |pskey|
  aws_ssm_parameter_store "delete testkitchen record #{pskey}" do
    path pskey
    aws_access_key node['aws_test']['key_id']
    aws_secret_access_key node['aws_test']['access_key']
    action :delete
  end
end
