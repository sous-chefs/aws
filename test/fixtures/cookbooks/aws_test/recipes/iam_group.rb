include_recipe 'aws::default'

aws_iam_group 'test-kitchen-group' do
  action :create
end
