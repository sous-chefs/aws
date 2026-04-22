control 'identity-suite' do
  impact 1.0
  title 'identity suite converges'

  describe file('/tmp/aws-live-identity-suite') do
    it { should exist }
  end
end
