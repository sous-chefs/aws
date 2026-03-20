# frozen_string_literal: true

require 'spec_helper'

describe 'aws_kinesis_stream' do
  step_into %w(aws_kinesis_stream)
  platform 'ubuntu'

  recipe do
    aws_kinesis_stream 'example-stream' do
      starting_shard_count 1
      action :nothing
    end
  end

  it 'compiles cleanly' do
    expect { chef_run }.not_to raise_error
  end
end
