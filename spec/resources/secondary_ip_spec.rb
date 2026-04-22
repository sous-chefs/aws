# frozen_string_literal: true

require 'spec_helper'

describe 'aws_secondary_ip' do
  step_into %w(aws_secondary_ip)
  platform 'ubuntu'

  recipe do
    aws_secondary_ip 'assign-secondary-ip' do
      ip '10.0.0.25'
      action :nothing
    end
  end

  it 'compiles cleanly' do
    expect { chef_run }.not_to raise_error
  end
end
