control 'orchestration-suite' do
  impact 1.0
  title 'orchestration suite converges'

  describe file('/tmp/aws-live-orchestration-suite') do
    it { should exist }
  end
end
