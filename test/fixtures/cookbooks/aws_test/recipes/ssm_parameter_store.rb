aws_ssm_parameter_store 'create testkitchen record' do
  name 'testkitchen'
  description 'testkitchen'
  value 'testkitchen'
  type 'String'
  action :create
  aws_access_key node['aws_test']['key_id']
  aws_secret_access_key node['aws_test']['access_key']
end

aws_ssm_parameter_store 'create test kitchen record' do
  name '/testkitchen/ClearTextString'
  description 'Test Kitchen String Parameter'
  value 'Clear Text Test Kitchen'
  type 'String'
  action :create
  aws_access_key node['aws_test']['key_id']
  aws_secret_access_key node['aws_test']['access_key']
end

aws_ssm_parameter_store 'create encrypted test kitchen record with default key' do
  name '/testkitchen/EncryptedStringDefaultKey'
  description 'Test Kitchen Encrypted Parameter - Default'
  value 'Encrypted Test Kitchen Default'
  type 'SecureString'
  action :create
  aws_access_key node['aws_test']['key_id']
  aws_secret_access_key node['aws_test']['access_key']
end

template '/tmp/file_with_data.txt' do
  source 'file_with_data.txt.erb'
  variables lazy {
    {
	  clear_value: get_aws_ssm_parameter_store('/testkitchen/ClearTextString'),
	  encrypted_value: get_aws_ssm_parameter_store('/testkitchen/EncryptedStringDefaultKey',true)
	}
  }
end
  


# need to figure out how to test this since it depends on a keyid
# aws_ssm_parameter_store "create encrypted test kitchen record" do
#  name '/testkitchen/EncryptedStringCustomKey'
#  description 'Test Kitchen Encrypted Parameter - Custom'
#  value 'Encrypted Test Kitchen Custom'
#  type 'SecureString'
#  key_id ''
#  action :create
#  aws_access_key node['aws_test']['key_id']
#  aws_secret_access_key node['aws_test']['access_key']
# end

aws_ssm_parameter_store 'create test kitchen record' do
  name '/testkitchen/ClearTextString'
  description 'NewString'
  value 'NewString'
  type 'String'
  overwrite true
  action :create
  aws_access_key node['aws_test']['key_id']
  aws_secret_access_key node['aws_test']['access_key']
end

aws_ssm_parameter_store 'delete testkitchen record' do
  name 'testkitchen'
  aws_access_key node['aws_test']['key_id']
  aws_secret_access_key node['aws_test']['access_key']
  action :delete
end
