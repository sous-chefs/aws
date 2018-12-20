require 'spec_helper'

describe 'aws::default' do
  # Nothing in this test is platform-specific, so use the latest Ubuntu for
  # simulated data.
  platform 'ubuntu'

  context 'does not raise an error' do
    it { expect { chef_run }.to_not raise_error }
  end
end
