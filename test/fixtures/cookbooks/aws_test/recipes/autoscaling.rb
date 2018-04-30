aws_autoscaling 'attach_instance' do
  action :attach_instance
  asg_name 'Test'
end
  
aws_autoscaling 'enter_standby' do
  should_decrement_desired_capacity false
  action :enter_standby
end

 aws_autoscaling 'exit_standby' do
   action :exit_standby
 end
 
aws_autoscaling 'detach_instance' do
  should_decrement_desired_capacity false
  action :detach_instance
end