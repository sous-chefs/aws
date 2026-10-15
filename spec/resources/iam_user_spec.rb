# frozen_string_literal: true

require 'spec_helper'

describe 'aws_iam_user' do
  step_into %w(aws_iam_user)
  platform 'ubuntu'

  recipe do
    aws_iam_user 'example-user' do
      action :nothing
    end
  end

  it 'compiles cleanly' do
    expect { chef_run }.not_to raise_error
  end
end
