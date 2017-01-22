aws_cloudwatch 'kitchen_test_alarm' do
  aws_access_key node['aws_test']['key_id']
  aws_secret_access_key node['aws_test']['access_key']
  period node['aws_test']['cloudwatch']['period']
  evaluation_periods node['aws_test']['cloudwatch']['evaluation_periods']
  threshold node['aws_test']['cloudwatch']['threshold']
  comparison_operator node['aws_test']['cloudwatch']['comparison_operator']
  metric_name node['aws_test']['cloudwatch']['metric_name']
  namespace node['aws_test']['cloudwatch']['namespace']
  statistic node['aws_test']['cloudwatch']['statistic']
  dimensions node['aws_test']['cloudwatch']['dimensions']
  actions_enabled node['aws_test']['cloudwatch']['actions_enabled']
  alarm_actions node['aws_test']['cloudwatch']['alarm_actions']
  action :create
end

aws_cloudwatch 'kitchen_test_alarm' do
  aws_access_key node['aws_test']['key_id']
  aws_secret_access_key node['aws_test']['access_key']
  action :disable_action
end

aws_cloudwatch 'kitchen_test_alarm' do
  aws_access_key node['aws_test']['key_id']
  aws_secret_access_key node['aws_test']['access_key']
  action :enable_action
end

aws_cloudwatch 'kitchen_test_alarm' do
  aws_access_key node['aws_test']['key_id']
  aws_secret_access_key node['aws_test']['access_key']
  action :delete
end
