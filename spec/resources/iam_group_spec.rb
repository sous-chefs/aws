# frozen_string_literal: true

require 'spec_helper'

describe 'aws_iam_group' do
  step_into %w(aws_iam_group)
  platform 'ubuntu'

  recipe do
    aws_iam_group 'example-group' do
      action :nothing
    end
  end

  it 'compiles cleanly' do
    expect { chef_run }.not_to raise_error
  end
end
