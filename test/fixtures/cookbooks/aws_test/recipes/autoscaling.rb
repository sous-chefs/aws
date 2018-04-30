aws_autoscaling 'attach_instance' do
  action :attach_instance
  asg_name 'Test'
end

ruby_block 'give_time_to_attach' do
  block do
    sleep(60)
  end
end
  
aws_autoscaling 'enter_standby' do
  action :enter_standby
end

ruby_block 'give_time_to_enter_standby' do
  block do
    sleep(5)
  end
end

 aws_autoscaling 'exit_standby' do
   action :exit_standby
 end

 ruby_block 'give_time_to_exit_standby' do
   block do
     sleep(30)
   end
 end

aws_autoscaling 'detach_instance' do
  action :detach_instance
end