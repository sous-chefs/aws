# frozen_string_literal: true

require 'spec_helper'

describe 'aws_instance_role' do
  step_into %w(aws_instance_role)
  platform 'ubuntu'

  recipe do
    aws_instance_role 'example' do
      action :nothing
    end
  end

  it 'compiles cleanly' do
    expect { chef_run }.not_to raise_error
  end
end
