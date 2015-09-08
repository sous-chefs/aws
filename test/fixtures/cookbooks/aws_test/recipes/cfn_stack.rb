aws_cfn_stack 'kitchen-test-stack' do
  action :create
  template_source 'kitchen-test-stack.tpl'
end
