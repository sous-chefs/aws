include Opscode::Aws::IAM

require 'json'

use_inline_resources

def whyrun_supported?
  true
end

# role_exists - logic for checking if the user exists
def role_exists?(role_name)
  resp = iam.get_role(role_name: role_name)
  if resp.length > 0
    true
  else
    false
  end
rescue ::Aws::IAM::Errors::NoSuchEntity
  false
end

# assume_role_policy_changed - get the assume role policy doc, unescaped,
# and compare with content in new_resource
def assume_role_policy_changed?
  resp = iam.get_role(role_name: new_resource.role_name)
  if URI.unescape(resp.role.assume_role_policy_document) == JSON.dump(JSON.parse(new_resource.assume_role_policy_document))
    false
  else
    true
  end
end

action :create do
  if role_exists?(new_resource.role_name)
    # update the role's policy document
    if assume_role_policy_changed?
      converge_by("update assume role policy for role #{new_resource.role_name}") do
        Chef::Log.debug("update assume role policy for role #{new_resource.role_name}")
        iam.update_assume_role_policy(
          role_name: new_resource.role_name,
          policy_document: new_resource.assume_role_policy_document
        )
        new_resource.updated_by_last_action(true)
      end
    end
    # check for updated managed policies
    resp = iam.list_attached_role_policies(role_name: new_resource.role_name)
    new_policies = new_resource.policy_members
    resp.attached_policies.each do |policy|
      # delete removed policies if new_resource.remove_policy_members == true
      if !new_resource.policy_members.include?(policy.policy_arn) && new_resource.remove_policy_members == true
        converge_by("detach policy #{policy.policy_arn} for role #{new_resource.role_name}") do
          Chef::Log.debug("detach policy #{policy.policy_arn} for role #{new_resource.role_name}")
          iam.detach_role_policy(
            role_name: new_resource.role_name,
            policy_arn: policy.policy_arn
          )
          new_resource.updated_by_last_action(true)
        end
      end
      # remove policies that are present from the new policies to add
      if new_resource.policy_members.include?(policy.policy_arn)
        new_policies.delete(policy.policy_arn)
      end
    end
    # add any leftover new policies if they exist.
    if new_policies.length > 0
      converge_by("attach new policies to role #{new_resource.role_name}: #{new_policies.join(',')}") do
        Chef::Log.debug("attach new policies to role #{new_resource.role_name}: #{new_policies.join(',')}")
        new_policies.each do |policy|
          iam.attach_role_policy(
            role_name: new_resource.role_name,
            policy_arn: policy
          )
        end
        new_resource.updated_by_last_action(true)
      end
    end
  else
    converge_by("create role #{new_resource.role_name}") do
      Chef::Log.debug("create role #{new_resource.role_name}")
      iam.create_role(
        path: new_resource.path,
        role_name: new_resource.role_name,
        assume_role_policy_document: new_resource.assume_role_policy_document
      )
      # attach role policies
      new_resource.policy_members.each do |policy|
        iam.attach_role_policy(
          role_name: new_resource.role_name,
          policy_arn: policy
        )
      end
      new_resource.updated_by_last_action(true)
    end
  end
end

action :delete do
  if role_exists?(new_resource.role_name)
    converge_by("delete role #{new_resource.role_name}") do
      Chef::Log.debug("delete role #{new_resource.role_name}")
      # detatch policies
      resp = iam.list_attached_role_policies(
        role_name: new_resource.role_name
      )
      resp.attached_policies.each do |policy|
        iam.detach_role_policy(
          role_name: new_resource.role_name,
          policy_arn: policy.policy_arn
        )
      end
      iam.delete_role(role_name: new_resource.role_name)
      new_resource.updated_by_last_action(true)
    end
  end
end
