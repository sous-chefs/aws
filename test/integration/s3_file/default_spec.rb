describe file('/tmp/a_file_2') do
  it { should be_file }
end

describe file('/tmp/a_file') do
  it { should be_file }
end
