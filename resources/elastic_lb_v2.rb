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

property :name,                  String
property :subnets,               Array, required: true
property :tags,                  Hash
property :scheme,                callbacks: {
  'Scheme must be either internet-facing or internal' => lambda do |scheme|
    %w(internet-facing internal).include? scheme
  end
}

load_current_value do
  current_value_does_not_exist! unless lb
  subnets lb.availability_zones.map(&:subnet_id)
  raise 'Scheme of an existing LB cannot be modified' unless scheme == lb.scheme
  scheme lb.scheme
  tags current_tags_hash
end

action :create do
  if lb
    converge_if_changed :subnets do
      converge_by("Modify the subnets associated with #{name}") do
        elbv2.set_subnets(load_balancer_arn: lb.load_balancer_arn, subnets: subnets)
      end
    end

    converge_if_changed :tags do
      converge_by("Modify the tags associated with #{name}") do
        tags_to_add    = Hash[*(tags.to_a - current_tags_hash.to_a).flatten].map { |k, v| { k => v } }
        tags_to_remove = Hash[*(current_tags_hash.to_a - tags.to_a).flatten].map { |k, v| { k => v } }

        elbv2.add_tags    resource_arns: [lb.load_balancer_arn], tags: tags_to_add
        elbv2.remove_tags resource_arns: [lb.load_balancer_arn], tags: tags_to_remove
      end
    end
  else
    converge_by("Create v2 load balancer #{name}") do
      elbv2.create_load_balancer(
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
  return unless lb
  converge_by("Removing v2 load balancer #{name}") do
    elbv2.delete_load_balancer load_balacer_arn: lb.load_balancer_arn
  end
end

def lb
  @lb ||= begin
    elbv2.describe_load_balancers(names: [name]).load_balancers.first
  rescue Aws::ElasticLoadBalancingV2::Errors::LoadBalancerNotFound
    nil
  end
end

def current_tags_hash
  @current_tags_hash ||= begin
    tag_object = elbv2.describe_tags(resource_arns: [lb.load_balancer_arn])
    tag_object.tag_descriptions.first.tags.each_with_object { |tag, memo| memo[tag.key] = tag.value }
  end
end
