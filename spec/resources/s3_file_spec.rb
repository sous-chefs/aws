# frozen_string_literal: true

require 'spec_helper'

describe 'aws_s3_file' do
  step_into %w(aws_s3_file)
  platform 'ubuntu'

  recipe do
    aws_s3_file '/tmp/example' do
      action :nothing
    end
  end

  it 'compiles cleanly' do
    expect { chef_run }.not_to raise_error
  end
end
