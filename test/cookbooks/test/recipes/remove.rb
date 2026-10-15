# frozen_string_literal: true

aws_cloudwatch_agent 'default' do
  action :remove
end

aws_ssm_agent 'default' do
  action :remove
end
