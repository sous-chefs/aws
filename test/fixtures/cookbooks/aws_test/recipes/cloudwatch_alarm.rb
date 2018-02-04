aws_cloudwatch 'kitchen_test_alarm' do
  aws_access_key node['aws_test']['key_id']
  aws_secret_access_key node['aws_test']['access_key']
  aws_session_token node['aws_test']['session_token']
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
  aws_session_token node['aws_test']['session_token']
  action :disable_action
end

aws_cloudwatch 'kitchen_test_alarm' do
  aws_access_key node['aws_test']['key_id']
  aws_secret_access_key node['aws_test']['access_key']
  aws_session_token node['aws_test']['session_token']
  action :enable_action
end

aws_cloudwatch 'kitchen_test_alarm' do
  aws_access_key node['aws_test']['key_id']
  aws_secret_access_key node['aws_test']['access_key']
  aws_session_token node['aws_test']['session_token']
  action :delete
end
