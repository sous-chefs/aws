# The ec2_hints recipe will be removed in a future version of this cookbook

Chef::Log.warn('The ec2_hint recipe is no longer necessary as Ohai detects EC2 instances automatically. 
It's worth noting that the ec2_hint recipe is not specifically for Ohai, Ohai uses ec2 plugin for detecting the ec2 instances. 
Ec2_hint is a Chef cookbook which helps you to use some specific attributes from Ohai's ec2 plugin and use them in your cookbook.
So if you are still using ec2_hint, you might be doing this for some specific functionalities or tasks.

It's always good practice to check the latest version of the cookbook you are using in order to ensure that, 
you are taking advantage of the latest features and bug fixes.
    
If your instances are not being automatically detected please file a bug at https://github.com/chef/ohai')
