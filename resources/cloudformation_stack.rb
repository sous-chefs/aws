property :stack_name, String, name_property: true
# location of the template body, located in the "files" cookbook dir
property :template_source, String, required: true
property :parameters, Array, default: []
property :disable_rollback, [true, false], default: false
property :iam_capability, [true, false], default: false
property :named_iam_capability, [true, false], default: false
property :stack_policy_body, String
property :region, String, default: lazy { fallback_region }

# authentication
property :aws_access_key, String
property :aws_secret_access_key, String
property :aws_session_token, String
property :aws_assume_role_arn, String
property :aws_role_session_name, String

include AwsCookbook::Ec2 # needed for aws_region helper

action :create do
  load_template_path
  if stack_exists?(new_resource.stack_name)
    # only update if stack changed
    if cfn_stack_changed? || cfn_params_chagned?
      converge_by("update stack #{new_resource.stack_name}") do
        options = build_cfn_options
        options.delete(:disable_rollback)
        cfn.update_stack(options)
      end
    end
  else
    converge_by("create stack #{new_resource.stack_name}") do
      options = build_cfn_options
      cfn.create_stack(options)
    end
  end
end

action :delete do
  if stack_exists?(new_resource.stack_name)
    converge_by("delete stack #{new_resource.stack_name}") do
      cfn.delete_stack(stack_name: new_resource.stack_name)
    end
  end
end

action_class do
  include AwsCookbook::Ec2

  require 'fileutils'

  def cfn
    require 'aws-sdk'

    Chef::Log.debug('Initializing the CloudFormation Client')
    @cfn ||= create_aws_interface(::Aws::CloudFormation::Client, region: new_resource.region)
  end

  def load_template_path
    cookbook = run_context.cookbook_collection[new_resource.cookbook_name]
    file_cache_location = cookbook.preferred_filename_on_disk_location(run_context.node, :files, new_resource.template_source)
    if file_cache_location.nil?
      raise "Cannot find #{new_resource.template_source} in cookbook!"
    else
      @template_path = file_cache_location
    end
  end

  # build_cfn_options - build options hash for create_stack based off of
  # new_resource data
  def build_cfn_options
    options = {
      stack_name: new_resource.stack_name,
      # make sure you call this after you save the file
      template_body: ::IO.read(@template_path),
      parameters: new_resource.parameters,
      disable_rollback: new_resource.disable_rollback,
      capabilities: [],
    }
    unless new_resource.stack_policy_body.nil?
      options[:stack_policy_body] = new_resource.stack_policy_body
    end
    options[:capabilities] << 'CAPABILITY_IAM' if new_resource.iam_capability
    options[:capabilities] << 'CAPABILITY_NAMED_IAM' if new_resource.named_iam_capability
    options
  end

  # cfn_stack_changed - get the stack JSON, and compare with local template
  def cfn_stack_changed?
    resp = cfn.get_template(stack_name: new_resource.stack_name)
    !(resp.template_body == ::IO.read(@template_path))
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
    if !resp.empty?
      true
    else
      false
    end
  rescue ::Aws::CloudFormation::Errors::ValidationError
    false
  end
end
