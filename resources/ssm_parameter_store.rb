property :description, String
property :value, String, required: true
property :type, String, required: true
property :key_id, String
property :overwrite, [true, false], default: true
property :with_decryption, [true, false], default: false
property :allowed_pattern, String
property :return_key, String
property :names, [String, Array], required: true
property :return_keys, [String, Hash]
property :path, String, required: true
property :recursive, [true, false], default: false
property :parameter_filters, String
property :next_token, String
property :max_results, Integer

# authentication
property :aws_access_key, String
property :aws_secret_access_key, String
property :aws_session_token, String
property :aws_assume_role_arn, String
property :aws_role_session_name, String
property :region, String, default: lazy { fallback_region }

include AwsCookbook::Ec2 # needed for aws_region helper

# allow use of the property names from the parameter store cookbook
alias_method :aws_access_key_id, :aws_access_key
alias_method :aws_region, :region

action :get do
  request = {
    name: name,
    with_decryption: with_decryption,
  }
  resp = ssm_client.get_parameter(request)
  node.run_state[new_resource.return_key] = resp.parameter.value
  Chef::Log.debug "Get parameter #{name}"
end

action :get_parameters do
  request = {
    names: names,
    with_decryption: with_decryption,
  }
  resp = ssm_client.get_parameters(request)
  secret_info = {}
  resp.parameters.each do |secret|
    secret_info["#{secret.name}"] = secret.value
  end
  Chef::Log.debug "Get parameters #{names}"
  node.run_state[new_resource.return_keys] = secret_info
end

action :get_parameters_by_path do
  secrets = []
  request = {
    path: path,
    recursive: recursive,
    parameter_filters: parameter_filters,
    with_decryption: with_decryption,
    max_results: max_results,
    next_token: next_token,
  }
  ssm_client.get_parameters_by_path(request).each do |resp|
    secrets.push(*resp.parameters)
  end
  secret_info = {}
  secrets.each do |secret|
    secret_info[secret.name] = secret.value
  end
  Chef::Log.debug "Get parameters by path #{path}"
  node.run_state[new_resource.return_keys] = secret_info
end

action :create do
  if write_parameter
    request = {
      name: name,
      description: description,
      value: value,
      type: type,
      key_id: key_id,
      overwrite: overwrite,
      allowed_pattern: allowed_pattern,
    }
    ssm_client.put_parameter(request)
    Chef::Log.debug "Put parameter #{name}"
  end
end

action :delete do
  request = {
    name: name,
  }
  ssm_client.delete_parameter(request)
  Chef::Log.info "parameter deleted: #{name}"
end

action_class do
  include AwsCookbook::Ec2

  def name
    @name ||= new_resource.name
  end

  def value
    @value ||= new_resource.value
  end

  def type
    @type ||= new_resource.type
  end

  def description
    @description ||= new_resource.description
  end

  def key_id
    @key_id ||= new_resource.key_id
  end

  def overwrite
    @overwrite ||= new_resource.overwrite
  end

  def with_decryption
    @with_decryption ||= new_resource.with_decryption
  end

  def allowed_pattern
    @allowed_pattern ||= new_resource.allowed_pattern
  end

  def names
    @names ||= new_resource.names
  end

  def path
    @path ||= new_resource.path
  end

  def recursive
    @recursive ||= new_resource.recursive
  end

  def parameter_filters
    @parameter_filters ||= new_resource.parameter_filters
  end

  def next_token
    @next_token ||= new_resource.next_token
  end

  def max_results
    @max_results ||= new_resource.max_results
  end

  def write_parameter
    # If the paremeter doesn't exist or one of the values has changed and overwrite
    # is set to true then we'll write the parameter.

    request = {
      name: name,
      with_decryption: (type == 'SecureString'),
    }
    response = ssm_client.get_parameter(request)
    return false if response.parameter.name == name && response.parameter.value == value
    return true if new_resource.overwrite
    false
  rescue Aws::SSM::Errors::ParameterNotFound => msg
    # Paremeter doesn't exist
    Chef::Log.info "get_parameter exception: #{msg}"
    true
  end

  def ssm_client
    @ssm ||= begin
      require 'aws-sdk'
      Chef::Log.debug('Initializing Aws::SSM::Client')
      create_aws_interface(::Aws::SSM::Client, region: new_resource.region)
    end
  end
end
