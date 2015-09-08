include Opscode::Aws::CloudFormation

def whyrun_supported?
  true
end

# some shared variables
# @template_cache_path = File.join(Chef::Config[:file_cache_path], new_resource.template_source)

# build_cfn_options - embedded file resource to move template file to cache dir.
# this allows for possible future update logic, plus a easy place to get at the data
def save_cfn_template
  f = cookbook_file ::File.join(Chef::Config[:file_cache_path], new_resource.template_source) do
    action :create
    source new_resource.template_source
    cookbook new_resource.cookbook_name
    action :nothing
  end
  f.run_action(:create)
  f.updated_by_last_action?
end

# build_cfn_options - build options hash for create_stack based off of
# new_resource data
def build_cfn_options
  options = {
    stack_name: new_resource.stack_name,
    # make sure you call this after you save the file
    template_body: ::IO.read(::File.join(Chef::Config[:file_cache_path], new_resource.template_source)),
    parameters: new_resource.parameters,
    disable_rollback: new_resource.disable_rollback
  }
  unless new_resource.stack_policy_body.nil?
    options[:stack_policy_body] = new_resource.stack_policy_body
  end
  options
end

# cfn_stack_changed - get the stack JSON, and compare with local template
def cfn_stack_changed?
  resp = cfn.get_template(stack_name: new_resource.stack_name)
  if resp.template_body == ::IO.read(::File.join(Chef::Config[:file_cache_path], new_resource.template_source))
    false
  else
    true
  end
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
  save_cfn_template
  if stack_exists?(new_resource.stack_name)
    # only update if stack changed
    if cfn_stack_changed?
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
