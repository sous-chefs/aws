# frozen_string_literal: true

require 'spec_helper'

describe 'aws_route53_record' do
  step_into %w(aws_route53_record)
  platform 'ubuntu'

  recipe do
    aws_route53_record 'www.example.com' do
      type 'A'
      action :nothing
    end
  end

  it 'compiles cleanly' do
    expect { chef_run }.not_to raise_error
  end
end
