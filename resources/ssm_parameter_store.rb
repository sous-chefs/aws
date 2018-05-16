property :description,                 String
property :value,                       String, required: true
property :type,                        String, required: true
property :key_id,                      String
property :overwrite,                   [true, false], default: true
property :with_decryption,             [true, false], default: false
property :allowed_pattern,             String
property :return_key,                  String

# authentication
property :aws_access_key,        String
property :aws_secret_access_key, String
property :aws_session_token,     String
property :aws_assume_role_arn,   String
property :aws_role_session_name, String
property :region,                String, default: lazy { fallback_region }

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
