# frozen_string_literal: true

require 'spec_helper'

describe 'aws_autoscaling' do
  step_into %w(aws_autoscaling)
  platform 'ubuntu'

  recipe do
    aws_autoscaling 'example' do
      action :nothing
    end
  end

  it 'compiles cleanly' do
    expect { chef_run }.not_to raise_error
  end
end
