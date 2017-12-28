if defined?(ChefSpec)
  # cloudformation_stack
  def create_aws_cloudformation_stack(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aws_cloudformation_stack, :create, resource_name)
  end

  def delete_aws_cloudformation_stack(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aws_cloudformation_stack, :delete, resource_name)
  end

  # dynamodb_table
  def create_aws_dynamodb_table(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aws_dynamodb_table, :create, resource_name)
  end

  def delete_aws_dynamodb_table(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aws_dynamodb_table, :delete, resource_name)
  end

  # ebs_volume
  def create_aws_ebs_volume(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aws_ebs_volume, :create, resource_name)
  end

  def attach_aws_ebs_volume(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aws_ebs_volume, :attach, resource_name)
  end

  def detach_aws_ebs_volume(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aws_ebs_volume, :detach, resource_name)
  end

  def snapshot_aws_ebs_volume(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aws_ebs_volume, :snapshot, resource_name)
  end

  def prune_aws_ebs_volume(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aws_ebs_volume, :prune, resource_name)
  end

  # elastic_ip
  def associate_aws_elastic_ip(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aws_elastic_ip, :associate, resource_name)
  end

  def disassociate_aws_elastic_ip(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aws_elastic_ip, :disassociate, resource_name)
  end

  def allocate_aws_elastic_ip(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aws_elastic_ip, :allocate, resource_name)
  end

  # elastic_lb
  def associate_aws_elastic_lb(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aws_elastic_lb, :register, resource_name)
  end

  def disassociate_aws_elastic_lb(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aws_elastic_lb, :deregister, resource_name)
  end

  # iam_group
  def create_aws_iam_group(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aws_iam_group, :create, resource_name)
  end

  def delete_aws_iam_group(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aws_iam_group, :delete, resource_name)
  end

  # iam_policy
  def create_aws_iam_policy(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aws_iam_policy, :create, resource_name)
  end

  def delete_aws_iam_policy(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aws_iam_policy, :delete, resource_name)
  end

  # iam_role
  def create_aws_iam_role(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aws_iam_role, :create, resource_name)
  end

  def delete_aws_iam_role(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aws_iam_role, :delete, resource_name)
  end

  # iam_user
  def create_aws_iam_user(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aws_iam_user, :create, resource_name)
  end

  def delete_aws_iam_user(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aws_iam_user, :delete, resource_name)
  end

  # instance_monitoring
  def enable_aws_instance_monitoring(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aws_instance_monitoring, :enable, resource_name)
  end

  def disable_aws_instance_monitoring(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aws_instance_monitoring, :disable, resource_name)
  end

  # instance_term_protection
  def enable_aws_instance_term_protection(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aws_instance_term_protection, :enable, resource_name)
  end

  def disable_aws_instance_term_protection(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aws_instance_term_protection, :disable, resource_name)
  end

  # kinesis_stream
  def create_aws_kinesis_stream(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aws_kinesis_stream, :create, resource_name)
  end

  def delete_aws_kinesis_stream(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aws_kinesis_stream, :delete, resource_name)
  end

  # resource_tag
  def add_aws_resource_tag(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aws_resource_tag, :add, resource_name)
  end

  def update_aws_resource_tag(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aws_resource_tag, :update, resource_name)
  end

  def remove_aws_resource_tag(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aws_resource_tag, :remove, resource_name)
  end

  def force_remove_aws_resource_tag(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aws_resource_tag, :force_remove, resource_name)
  end

  # s3_bucket
  def create_aws_s3_bucket(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aws_s3_bucket, :create, resource_name)
  end

  def delete_aws_s3_bucket(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aws_s3_bucket, :delete, resource_name)
  end

  # s3_file
  def create_aws_s3_file(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aws_s3_file, :create, resource_name)
  end

  def create_if_missing_aws_s3_file(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aws_s3_file, :create_if_missing, resource_name)
  end

  def touch_aws_s3_file(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aws_s3_file, :touch, resource_name)
  end

  def delete_aws_s3_file(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aws_s3_file, :delete, resource_name)
  end

  # secondary_ip
  def assign_aws_secondary_ip(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aws_secondary_ip, :assign, resource_name)
  end

  # cloudwatch
  def create_aws_cloudwatch(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aws_cloudwatch, :create, resource_name)
  end

  def delete_aws_cloudwatch(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aws_cloudwatch, :delete, resource_name)
  end

  def disable_action_aws_cloudwatch(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aws_cloudwatch, :disable_action, resource_name)
  end

  def enable_action_aws_cloudwatch(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aws_cloudwatch, :enable_action, resource_name)
  end

  def create_aws_route53_record(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aws_route53_record, :create, resource_name)
  end

  def delete_aws_route53_record(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aws_route53_record, :delete, resource_name)
  end

  # System Manager Parameter Store
  def get_aws_ssm_parameter_store(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aws_parameter_store, :create, resource_name)
  end

  def create_aws_ssm_parameter_store(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aws_parameter_store, :create, resource_name)
  end

  def delete_aws_ssm_parameter_store(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aws_parameter_store, :delete, resource_name)
  end

  resources = %i(aws_cloudformation_stack aws_dynamodb_table aws_ebs_volume aws_elastic_ip aws_elastic_lb aws_iam_group aws_iam_policy aws_iam_role aws_iam_user aws_instance_monitoring aws_instance_term_protection aws_kinesis_stream aws_resource_tag aws_s3_bucket aws_s3_file aws_secondary_ip aws_cloudwatch aws_route53_record aws_ssm_parameter_store)

  resources.each do |resource|
    ChefSpec.define_matcher resource
  end
end
