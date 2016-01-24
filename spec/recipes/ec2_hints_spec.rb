require 'spec_helper'

describe 'aws::ec2_hints' do
  let(:chef_run) { ChefSpec::SoloRunner.converge(described_recipe) }

  it 'creates the ohai hint' do
    expect(chef_run).to create_ohai_hint('ec2').at_compile_time
  end

  it 'reloads ohai' do
    expect(chef_run).to reload_ohai('reload')
  end
end
