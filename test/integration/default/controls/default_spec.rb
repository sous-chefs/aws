control 'default-suite' do
  impact 1.0
  title 'default suite converges locally'

  describe file('/tmp/aws-default-suite-ran') do
    it { should exist }
    its('content') { should match(/default suite converged/) }
  end
end
