# frozen_string_literal: true

require 'spec_helper'

describe 'aws_ebs_volume' do
  step_into %w(aws_ebs_volume)
  platform 'ubuntu'

  recipe do
    aws_ebs_volume 'example-volume' do
      action :nothing
    end
  end

  it 'compiles cleanly' do
    expect { chef_run }.not_to raise_error
  end
end
