# This recipe is no longer needed to load the aws-sdk.
# Adding this recipe in the run_list will include a helper method
# called "instance_tags" which retuns a dictionary the current
# AWS Resoruce Tags configured for the node.

::Chef::Recipe.send(:include, Opscode::Aws::Helpers)
Chef::Log.warn('The default aws recipe does nothing except include helper methods. See the readme for information on using the aws resources')
