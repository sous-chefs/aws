control 'storage-suite' do
  impact 1.0
  title 'storage suite converges'

  describe file('/tmp/aws-live-storage-suite') do
    it { should exist }
  end
end
