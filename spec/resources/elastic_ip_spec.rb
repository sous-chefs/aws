# frozen_string_literal: true

require 'spec_helper'

describe 'aws_elastic_ip' do
  step_into %w(aws_elastic_ip)
  platform 'ubuntu'

  recipe do
    aws_elastic_ip '203.0.113.10' do
      action :nothing
    end
  end

  it 'compiles cleanly' do
    expect { chef_run }.not_to raise_error
  end
end
