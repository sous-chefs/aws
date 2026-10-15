# frozen_string_literal: true

require 'spec_helper'

describe 'aws_resource_tag' do
  step_into %w(aws_resource_tag)
  platform 'ubuntu'

  recipe do
    aws_resource_tag 'vol-1234abcd' do
      tags('Environment' => 'test')
      action :nothing
    end
  end

  it 'compiles cleanly' do
    expect { chef_run }.not_to raise_error
  end
end
