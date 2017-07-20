property :aws_access_key, String
property :aws_secret_access_key, String
property :aws_session_token, String
property :aws_assume_role_arn, String
property :aws_role_session_name, String
property :region, String, default: lazy { fallback_region }
property :instance_id, String, default: lazy { node['ec2']['instance_id'] }
property :profile_arn, String

include AwsCookbook::Ec2

action :associate do
  association = current_association
  if association.nil?
    converge_by('associate iam instance profile') do
      ec2.associate_iam_instance_profile(
        iam_instance_profile: {
          arn: new_resource.profile_arn,
        },
        instance_id: new_resource.instance_id
      )
    end
  elsif association.iam_instance_profile.arn != new_profile_arn
    converge_by('replace iam instance profile association') do
      ec2.replace_iam_instance_profile_association(
        iam_instance_profile: {
          arn: new_resource.profile_arn,
        },
        association_id: current_association.association_id
      )
    end
  end
end

action_class do
  include AwsCookbook::Ec2

  def current_association
    current_associations =
      ec2.describe_iam_instance_profile_associations(
        filters: [
          {
            name: 'instance-id',
            values: [new_resource.instance_id],
          },
        ]
      ).iam_instance_profile_associations
    if current_associations.empty?
      nil
    else
      current_associations[0]
    end
  end

  def new_profile_arn
    new_resource.profile_arn
  end
end
