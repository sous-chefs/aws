#
# Cookbook:: aws
# Resource:: ssm_parameter_store
#

resource_name :ssm_parameter_store
provides :aws_ssm_parameter_store

# => Define the Resource Properties
property :path, [String, Array], name_property: true

# => Retrieval Properties
property :recursive,       [FalseClass, TrueClass], default: false
property :with_decryption, [false, true], default: false
# => run_state key to put the Retrieved Value(s)
property :return_key,        String
property :parameter_filters, Array, required: false

# => Create Properties
property :value,           String
property :description,     String
property :type,            %w(String StringList SecureString)
property :key_id,          String
property :overwrite,       [false, true], default: true
property :allowed_pattern, String

# => AWS Config
property :aws_access_key, String
property :aws_secret_access_key, String
property :aws_session_token, String
property :aws_assume_role_arn, String
property :aws_role_session_name, String
property :region, String, default: lazy { fallback_region }

include AwsCookbook::Ec2 # needed for aws_region helper
include Chef::Mixin::DeepMerge

# allow use of the property names from the parameter store cookbook
alias_method :aws_access_key_id, :aws_access_key
alias_method :aws_region, :region
alias_method :return_keys, :return_key

# => Retrieve Single Parameter
action :get do
  request = {
    name: new_resource.path,
    with_decryption: new_resource.with_decryption,
  }
  Chef::Log.debug "Get parameter: #{request[:name]}"
  resp = ssm_client.get_parameter(request)
  node.run_state[new_resource.return_key] = resp.parameter.value
end

# => Retrieve Multiple Parameters
action :get_parameters do
  request = {
    names: Array(new_resource.path),
    with_decryption: new_resource.with_decryption,
  }
  Chef::Log.debug "Get parameters: #{request[:names]}"
  resp = ssm_client.get_parameters(request)
  secret_info = {}
  resp.parameters.each do |secret|
    secret_info[secret.name] = secret.value
  end
  node.run_state[new_resource.return_key] = secret_info
end

action :get_parameters_by_path do
  # => Build the Request
  request = {
    path: new_resource.path,
    recursive: new_resource.recursive,
    parameter_filters: new_resource.parameter_filters,
    with_decryption: new_resource.with_decryption,
    max_results: 10,
  }
  Chef::Log.debug "Get parameters by path #{request[:path]}"
  parms = []
  while (resp = ssm_client.get_parameters_by_path(request))
    parms.concat(resp.parameters)
    break unless resp.next_token
    request[:next_token] = resp.next_token
  end
  parms.each do |parm|
    # => Strip Leading Path
    pname = parm.name.sub(::Pathname.new(request[:path]).cleanpath.to_s, '')
    # => Convert the Param to a Hash
    hsh = param_to_hash(pname, parm.value)
    # => Merge the resulting Hash into the Destination
    deep_merge!(hsh, node.run_state[new_resource.return_key] ||= {})
  end
end

action :create do
  if write_parameter
    request = {
      name: new_resource.path,
      description: new_resource.description,
      value: new_resource.value,
      type: new_resource.type,
      key_id: new_resource.key_id,
      overwrite: new_resource.overwrite,
      allowed_pattern: new_resource.allowed_pattern,
    }
    Chef::Log.debug "Put parameter #{new_resource.path}"
    ssm_client.put_parameter(request)
  end
end

action :delete do
  request = {
    name: new_resource.path,
  }
  Chef::Log.info "Deleting Parameter: #{new_resource.path}"
  ssm_client.delete_parameter(request)
end

action_class do
  include AwsCookbook::Ec2

  def param_to_hash(path, value)
    # => Recursively descend a ParameterStore Path and build a Hash
    #  INPUT: '/Ensure/This/Path' = 'Exists'
    # OUTPUT: ['Ensure']['This']['Path'] => 'Exists'
    path.split('/').reject(&:empty?).reverse.inject(value) { |acc, elem| { elem => acc } }
  end

  def write_parameter
    request = {
      name: new_resource.path,
      with_decryption: (new_resource.type == 'SecureString'),
    }
    # => Poll the Parameter's existence
    r = ssm_client.get_parameter(request)
    return false if r.parameter.value == new_resource.value
    return true if new_resource.overwrite
    false
  rescue Aws::SSM::Errors::ParameterNotFound
    true
  end

  def ssm_client
    @ssm ||= begin
      require 'aws-sdk-ssm'
      Chef::Log.debug('Initializing Aws::SSM::Client')
      create_aws_interface(::Aws::SSM::Client, region: new_resource.region)
    end
  end
end
