# frozen_string_literal: true

require 'spec_helper'

describe 'aws_iam_role' do
  step_into %w(aws_iam_role)
  platform 'ubuntu'

  recipe do
    aws_iam_role 'example-role' do
      assume_role_policy_document '{"Version":"2012-10-17","Statement":[]}'
      action :nothing
    end
  end

  it 'compiles cleanly' do
    expect { chef_run }.not_to raise_error
  end
end
