# frozen_string_literal: true

require 'spec_helper'

describe 'aws_elastic_lb' do
  step_into %w(aws_elastic_lb)
  platform 'ubuntu'

  recipe do
    aws_elastic_lb 'example-elb' do
      action :nothing
    end
  end

  it 'compiles cleanly' do
    expect { chef_run }.not_to raise_error
  end
end
