property :user_name, String, name_property: true
property :path, String, default: '/'
property :region, String, default: lazy { fallback_region }

# authentication
property :aws_access_key, String
property :aws_secret_access_key, String
property :aws_session_token, String
property :aws_assume_role_arn, String
property :aws_role_session_name, String

include AwsCookbook::Ec2 # needed for aws_region helper

action :create do
  unless user_exists?(new_resource.user_name)
    converge_by("create IAM user #{new_resource.user_name}") do
      Chef::Log.debug("create IAM user #{new_resource.user_name}")
      iam.create_user(
        path: new_resource.path,
        user_name: new_resource.user_name
      )
    end
  end
end

action :delete do
  if user_exists?(new_resource.user_name)
    converge_by("delete IAM user #{new_resource.user_name}") do
      Chef::Log.debug("delete IAM user #{new_resource.user_name}")
      # remove user from member groups
      resp = iam.list_groups_for_user(user_name: new_resource.user_name)
      resp.groups.each do |group|
        iam.remove_user_from_group(
          group_name: group.group_name,
          user_name: new_resource.user_name
        )
      end
      iam.delete_user(user_name: new_resource.user_name)
    end
  end
end

action_class do
  include AwsCookbook::IAM

  # user_exists - logic for checking if the user exists
  def user_exists?(user_name)
    resp = iam.get_user(user_name: user_name)
    if !resp.empty?
      true
    else
      false
    end
  rescue ::Aws::IAM::Errors::NoSuchEntity
    false
  end
end
