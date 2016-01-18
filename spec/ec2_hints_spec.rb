require 'spec_helper'

describe 'aws::ec2_hints' do
  let(:chef_run) { ChefSpec::SoloRunner.converge(described_recipe) }

  it 'sets up the directory' do
    expect(chef_run).to create_directory('/etc/chef/ohai/hints').at_compile_time
  end

  it 'adds the hint file' do
    expect(chef_run).to create_file('/etc/chef/ohai/hints/ec2.json').at_compile_time
  end

  it 'reloads ohai' do
    expect(chef_run).to reload_ohai('reload')
  end
end
