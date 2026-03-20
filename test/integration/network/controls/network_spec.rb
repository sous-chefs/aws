control 'network-suite' do
  impact 1.0
  title 'network suite converges'

  describe file('/tmp/aws-live-network-suite') do
    it { should exist }
  end
end
