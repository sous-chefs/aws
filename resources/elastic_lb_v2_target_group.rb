# Prerequisites: None

include Opscode::Aws::ElbV2

actions :create, :delete
default_action :create

property :aws_access_key,        String
property :aws_secret_access_key, String
property :aws_session_token,     String
property :aws_assume_role_arn,   String
property :aws_role_session_name, String
property :region,                String

property :name,         String
property :vpc_id,       String, required: true
property :health_check, Hash
property :tags,         Hash
property :protocol,     String, required: true, callbacks: {
  'Protocol must be either HTTP or HTTPS' => ->(pr) { pr =~ /^https?$/ }
}
property :port,         required: true, callbacks: {
  'Port must be a number between 1 and 65535' => lambda do |cur_port|
    cur_port = cur_port.to_i
    cur_port > 0 && cur_port < 2**16
  end
}

load_current_value do
  current_value_does_not_exist! unless tg
  raise 'VPC ID of an existing target group cannot be modified' unless vpc_id == tg.vpc_id
  tags current_tags_hash
  health_check health_check_hash
end

action :create do
  if tg
    converge_if_changed :tags do
      converge_by("Modify the tags associated with #{name}") do
        tags_to_add    = Hash[*(tags.to_a - current_tags_hash.to_a).flatten].map { |k, v| { k => v } }
        tags_to_remove = Hash[*(current_tags_hash.to_a - tags.to_a).flatten].map { |k, v| { k => v } }

        elbv2.add_tags    resource_arns: [tg.target_group_arn], tags: tags_to_add
        elbv2.remove_tags resource_arns: [tg.target_group_arn], tags: tags_to_remove
      end
    end

    converge_if_changed :health_check do
      elbv2.modify_target_group health_check_hash.merge target_group_arn: tg.target_group_arn
    end
  else
    converge_by("Create target group #{name}") do
      elbv2.create_target_group(
        name: name,
        subnets: subnets,
        security_groups: security_groups,
        scheme: scheme,
        tags: tags
      )
    end
  end
end

action :delete do
  return unless tg
  converge_by("Removing target group #{name}") do
    elbv2.delete_target_group target_group_arn: tg.target_group_arn
  end
end

def tg
  @tg ||= begin
    elbv2.describe_target_groups(names: [name]).target_groups.first
  rescue Aws::ElasticLoadBalancingV2::Errors::TargetGroupNotFound
    nil
  end
end

def health_check_hash
  output = { matcher: { http_code: tg.matcher.http_code } }

  %i(
    health_check_protocol
    health_check_port
    health_check_interval_seconds
    health_check_timeout_seconds
    healthy_threshold_count
    unhealthy_threshold_count
    health_check_path
  ).each { |key_sym| output[key_sym] = tg.send key_sym }
  output
end

def current_tags_hash
  @current_tags_hash ||= begin
    tag_object = elbv2.describe_tags(resource_arns: [tg.target_group_arn])
    tag_object.tag_descriptions.first.tags.each_with_object { |tag, memo| memo[tag.key] = tag.value }
  end
end
