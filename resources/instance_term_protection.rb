property :aws_access_key, String
property :aws_secret_access_key, String
property :aws_session_token, String
property :aws_assume_role_arn, String
property :aws_role_session_name, String
property :region, String, default: lazy { fallback_region }
property :instance_id, String, default: lazy { node['ec2']['instance_id'] }

include AwsCookbook::Ec2 # needed for aws_region helper

action :enable do
  unless term_protection_enabled?
    converge_by('enable termination protection for the instance') do
      ec2.modify_instance_attribute(instance_id: new_resource.instance_id, disable_api_termination: { value: true })
    end
  end
end

action :disable do
  if term_protection_enabled?
    converge_by('disable termination protection for the instance') do
      ec2.modify_instance_attribute(instance_id: new_resource.instance_id, disable_api_termination: { value: false })
    end
  end
end

action_class do
  include AwsCookbook::Ec2

  def term_protection_enabled?
    term_protection_state = ec2.describe_instance_attribute(
      attribute: 'disableApiTermination',
      instance_id: new_resource.instance_id
    ).to_h[:disable_api_termination][:value]
    Chef::Log.info("Current termination protection state for instance #{new_resource.instance_id} is #{term_protection_state}")
    term_protection_state
  end
end
