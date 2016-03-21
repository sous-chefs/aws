describe command('/opt/chef/embedded/bin/gem list') do
  its('stdout') { should match /aws-sdk \(/ }
end

hint_path = case os[:family]
            when 'windows'
              'C:/chef/ohai/hints'
            else
              '/etc/chef/ohai/hints'
            end

describe file("#{hint_path}/ec2.json") do
  it { should be_file }
end
