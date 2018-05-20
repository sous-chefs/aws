aws_autoscaling 'create_launch_config' do
  action :create_launch_config
end

aws_autoscaling 'create_asg' do
  action :create_asg
end

aws_autoscaling 'attach_instance' do
  action :attach_instance
  asg_name 'AWS_ASG_Test'
end

aws_autoscaling 'attach_instance_try2' do
  action :attach_instance
  asg_name 'AWS_ASG_Test'
end

aws_autoscaling 'enter_standby' do
  action :enter_standby
end

aws_autoscaling 'enter_standby_try2' do
  action :enter_standby
end

aws_autoscaling 'exit_standby' do
  action :exit_standby
end

aws_autoscaling 'exit_standby_try2' do
  action :exit_standby
end

aws_autoscaling 'detach_instance' do
  action :detach_instance
end

aws_autoscaling 'detach_instance_try2' do
  action :detach_instance
end

aws_autoscaling 'delete_asg' do
  action :delete_asg
end

aws_autoscaling 'delete_launch_config' do
  action :delete_launch_config
end
