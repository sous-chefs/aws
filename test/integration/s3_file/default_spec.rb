describe command('/opt/chef/embedded/bin/gem list') do
  its('stdout') { should match /aws-sdk \(/ }
end

describe file('/tmp/a_file_2') do
  it { should be_file }
end

describe file('/tmp/a_file') do
  it { should be_file }
end

describe file('/tmp/file_with_group_by_name') do
  it { should be_file }
  its('group') { should eq 'testgroup' }
end

describe file('/tmp/file_with_group_by_gid') do
  it { should be_file }
end
