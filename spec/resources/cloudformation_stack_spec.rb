# frozen_string_literal: true

require 'spec_helper'

describe 'aws_cloudformation_stack' do
  step_into %w(aws_cloudformation_stack)
  platform 'ubuntu'

  recipe do
    aws_cloudformation_stack 'example-stack' do
      template_source 'stack.json'
      action :nothing
    end
  end

  it 'compiles cleanly' do
    expect { chef_run }.not_to raise_error
  end
end
