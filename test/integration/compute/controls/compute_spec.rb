control 'compute-suite' do
  impact 1.0
  title 'compute suite converges'

  describe file('/tmp/aws-live-compute-suite') do
    it { should exist }
  end
end
