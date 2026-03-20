# frozen_string_literal: true

require 'spec_helper'

describe 'aws_ssm_parameter_store' do
  step_into %w(aws_ssm_parameter_store)
  platform 'ubuntu'

  recipe do
    aws_ssm_parameter_store 'example-parameter' do
      action :nothing
    end
  end

  it 'compiles cleanly' do
    expect { chef_run }.not_to raise_error
  end
end
