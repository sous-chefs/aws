include Opscode::Aws::CloudFormation
require 'fileutils'

use_inline_resources

def whyrun_supported?
  true
end

# build_cfn_options - build options hash for create_stack based off of
# new_resource data
def build_cfn_options
  options = {
    stack_name: new_resource.stack_name,
    # make sure you call this after you save the file
    template_body: ::IO.read(@template_path),
    parameters: new_resource.parameters,
    disable_rollback: new_resource.disable_rollback
  }
  unless new_resource.stack_policy_body.nil?
    options[:stack_policy_body] = new_resource.stack_policy_body
  end
  options[:capabilities] = ['CAPABILITY_IAM'] if new_resource.iam_capability
  options
end

# cfn_stack_changed - get the stack JSON, and compare with local template
def cfn_stack_changed?
  resp = cfn.get_template(stack_name: new_resource.stack_name)
  if resp.template_body == ::IO.read(@template_path)
    false
  else
    true
  end
end

# cfn_params_chagned - see if parameters have updated
def cfn_params_chagned?
  resp = cfn.describe_stacks(stack_name: new_resource.stack_name)
  resp.stacks[0].parameters.each do |existing_param|
    new_params = new_resource.parameters
    index = new_params.index { |x| x[:parameter_key] == existing_param[:parameter_key] }
    next if index.nil?
    return true unless new_params[index][:parameter_value] == existing_param[:parameter_value]
  end
  false
end

# does_stack_exist - logic for checking if the stack exists
def stack_exists?(stack_name)
  resp = cfn.describe_stacks(stack_name: stack_name)
  if resp.length > 0
    true
  else
    false
  end
rescue ::Aws::CloudFormation::Errors::ValidationError
  false
end

action :create do
  load_template_path
  if stack_exists?(new_resource.stack_name)
    # only update if stack changed
    if cfn_stack_changed? || cfn_params_chagned?
      converge_by("update stack #{new_resource.stack_name}") do
        Chef::Log.debug("update stack #{new_resource.stack_name}")
        options = build_cfn_options
        options.delete(:disable_rollback)
        cfn.update_stack(options)
        new_resource.updated_by_last_action(true)
      end
    end
  else
    converge_by("create stack #{new_resource.stack_name}") do
      Chef::Log.debug("create stack #{new_resource.stack_name}")
      options = build_cfn_options
      cfn.create_stack(options)
      new_resource.updated_by_last_action(true)
    end
  end
end

action :delete do
  if stack_exists?(new_resource.stack_name)
    converge_by("delete stack #{new_resource.stack_name}") do
      Chef::Log.debug("delete stack #{new_resource.stack_name}")
      cfn.delete_stack(stack_name: new_resource.stack_name)
      new_resource.updated_by_last_action(true)
    end
  end
end

private

def load_template_path
  cookbook = run_context.cookbook_collection[new_resource.cookbook_name]
  file_cache_location = cookbook.preferred_filename_on_disk_location(run_context.node, :files, new_resource.template_source)
  if file_cache_location.nil?
    raise "Cannot find #{new_resource.template_source} in cookbook!"
  else
    @template_path = file_cache_location
  end
end
