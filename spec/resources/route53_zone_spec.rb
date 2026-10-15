# frozen_string_literal: true

require 'spec_helper'

describe 'aws_route53_zone' do
  step_into %w(aws_route53_zone)
  platform 'ubuntu'

  recipe do
    aws_route53_zone 'example.com' do
      action :nothing
    end
  end

  it 'compiles cleanly' do
    expect { chef_run }.not_to raise_error
  end
end
