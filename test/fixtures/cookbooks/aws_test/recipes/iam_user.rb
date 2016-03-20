include_recipe 'aws::default'

aws_iam_user 'test-kitchen-user' do
  action :create
end
