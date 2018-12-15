describe json('/tmp/ssm_parameters.json') do
  # => Get (:get)
  its('clear_value') { should eq 'Clear Text Test Kitchen' }
  its('decrypted_value') { should eq 'Encrypted Test Kitchen Default' }
  its('path1_value') { should eq 'path1_value' }
  its('path2_value') { should eq 'path2_value' }
  its('parm1_value') { should eq 'Clear Text Test Kitchen' }
  its('parm2_value') { should eq 'testkitchen' }

  # => Get Parameters (:get_parameters)
  its(%w(parameter_values /testkitchen)) { should eq 'testkitchen' }
  its(%w(parameter_values /testkitchen/ClearTextString)) { should eq 'Clear Text Test Kitchen' }

  # => Get Parameters by Path - Hash Return (:get_parameters_by_path)
  its(%w(path_values path1)) { should eq 'path1_value' }
  its(%w(path_values path2)) { should eq 'path2_value' }
end
