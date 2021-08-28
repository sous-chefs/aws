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

2.times do |index|
  pname = "path#{index + 1}"
  aws_ssm_parameter_store "create test kitchen record #{pname}" do
    path "/testkitchen/pathtest/#{pname}"
    description "#{pname} is cool"
    value "#{pname}_value"
    type 'String'
    action :create
    aws_access_key node['aws_test']['key_id']
    aws_secret_access_key node['aws_test']['access_key']
  end
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

aws_ssm_parameter_store 'Get Parameters' do
  path ['/testkitchen/ClearTextString', '/testkitchen']
  return_key 'parameter_values'
  action :get_parameters
  aws_access_key node['aws_test']['key_id']
  aws_secret_access_key node['aws_test']['access_key']
end

aws_ssm_parameter_store 'Get Parameters by Path' do
  path '/testkitchen/pathtest/'
  recursive true
  with_decryption true
  return_key 'path_values'
  action :get_parameters_by_path
  aws_access_key node['aws_test']['key_id']
  aws_secret_access_key node['aws_test']['access_key']
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

file '/tmp/ssm_parameters.json' do
  content lazy {
    Chef::JSONCompat.to_json_pretty(
      clear_value: node.run_state['clear_value'],
      # :decrypted_custom_value => node.run_state['decrypted_custom_value'],
      decrypted_value: node.run_state['decrypted_value'],
      path_values: node.run_state['path_values'],
      parameter_values: node.run_state['parameter_values'],
      path1_value: node.run_state['path_values']['path1'],
      path2_value: node.run_state['path_values']['path2'],
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
aws_ssm_parameter_store 'Delete TestKitchen Records' do
  path 'testkitchen'
  aws_access_key node['aws_test']['key_id']
  aws_secret_access_key node['aws_test']['access_key']
  action :delete
end
