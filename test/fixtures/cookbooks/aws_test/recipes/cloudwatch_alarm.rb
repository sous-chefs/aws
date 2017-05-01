aws_cloudwatch 'kitchen_test_alarm' do
  aws_access_key node['aws_test']['key_id']
  aws_secret_access_key node['aws_test']['access_key']
  period 21600
  evaluation_periods 2
  threshold 50.0
  comparison_operator 'LessThanThreshold'
  metric_name 'CPUUtilization'
  namespace 'AWS/EC2'
  statistic 'Maximum'
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
