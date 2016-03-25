aws_cloudformation_stack 'kitchen-test-stack' do
  aws_access_key node['aws_test']['key_id']
  aws_secret_access_key node['aws_test']['access_key']
  action :create
  template_source 'kitchen-test-stack.tpl'
end

aws_cloudformation_stack 'kitchen-test-stack' do
  aws_access_key node['aws_test']['key_id']
  aws_secret_access_key node['aws_test']['access_key']
  action :delete
end
