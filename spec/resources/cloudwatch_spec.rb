# frozen_string_literal: true

require 'spec_helper'

describe 'aws_cloudwatch' do
  step_into %w(aws_cloudwatch)
  platform 'ubuntu'

  recipe do
    aws_cloudwatch 'example-alarm' do
      action :nothing
    end
  end

  it 'compiles cleanly' do
    expect { chef_run }.not_to raise_error
  end
end
