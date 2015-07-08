require 'spec_helper'

describe 'aws::default' do
  let(:chef_run) { ChefSpec::SoloRunner.converge(described_recipe) }

  it 'installs chef_gem aws-sdk' do
    expect(chef_run).to install_chef_gem('aws-sdk')
  end
end
