property :policy_name, String, name_property: true
property :path, String, default: '/'
property :policy_document, String, required: true
property :account_id, String
property :region, String, default: lazy { fallback_region }

# authentication
property :aws_access_key, String
property :aws_secret_access_key, String
property :aws_session_token, String
property :aws_assume_role_arn, String
property :aws_role_session_name, String

include AwsCookbook::Ec2 # needed for aws_region helper

action :create do
  if policy_exists?(new_resource.policy_name)
    if policy_changed?
      converge_by("update policy #{new_resource.policy_name}") do
        iam.create_policy_version(
          policy_arn: make_policy_arn(new_resource.policy_name),
          policy_document: new_resource.policy_document,
          set_as_default: true
        )
      end
    end
  else
    converge_by("create policy #{new_resource.policy_name}") do
      iam.create_policy(
        path: new_resource.path,
        policy_name: new_resource.policy_name,
        policy_document: new_resource.policy_document
      )
    end
  end
end

action :delete do
  if policy_exists?(new_resource.policy_name)
    converge_by("delete policy #{new_resource.policy_name}") do
      # un-attach all associated entities (ie: users, groups, roles)
      resp = iam.list_entities_for_policy(policy_arn: make_policy_arn(new_resource.policy_name))
      resp.policy_users.each do |user|
        iam.detach_user_policy(
          policy_arn: make_policy_arn(new_resource.policy_name),
          user_name: user.user_name
        )
      end
      resp.policy_groups.each do |group|
        iam.detach_group_policy(
          policy_arn: make_policy_arn(new_resource.policy_name),
          group_name: group.group_name
        )
      end
      resp.policy_roles.each do |role|
        iam.detach_role_policy(
          policy_arn: make_policy_arn(new_resource.policy_name),
          role_name: role.role_name
        )
      end
      # delete previous policy versions
      resp = iam.list_policy_versions(policy_arn: make_policy_arn(new_resource.policy_name))
      resp.versions.each do |version|
        next if version.is_default_version
        iam.delete_policy_version(
          policy_arn: make_policy_arn(new_resource.policy_name),
          version_id: version.version_id
        )
      end
      # delete the policy
      iam.delete_policy(policy_arn: make_policy_arn(new_resource.policy_name))
    end
  end
end

action_class do
  include AwsCookbook::IAM
  include AwsCookbook::STS

  # make_policy_arn - construct the policy ARN - this is needed for some
  # IAM API calls that do not take a direct policy name.
  def make_policy_arn(policy_name)
    # we use the STS caller identity for this. If a regular user is signed in,
    # it uses their user ARN. If it is an assumed role or federated user it
    # returns an STS ARN.
    if new_resource.account_id.to_s.empty?
      resp = sts.get_caller_identity
      account_id = /^arn:aws:(iam|sts)::(\d+):.*$/.match(resp.arn)[2]
    else
      account_id = new_resource.account_id
    end
    "arn:aws:iam::#{account_id}:policy/#{policy_name}"
  end

  # policy_exists - logic for checking if the policy exists
  def policy_exists?(policy_name)
    resp = iam.get_policy(policy_arn: make_policy_arn(policy_name))
    if !resp.empty?
      true
    else
      false
    end
  rescue ::Aws::IAM::Errors::NoSuchEntity
    false
  end

  # policy_changed - get the policy doc, unescaped, and compare with content in new_resource
  def policy_changed?
    version = iam.get_policy(policy_arn: make_policy_arn(new_resource.policy_name)).policy.default_version_id
    resp = iam.get_policy_version(
      policy_arn: make_policy_arn(new_resource.policy_name),
      version_id: version
    )
    !(URI.unescape(resp.policy_version.document) == new_resource.policy_document)
  end
end
