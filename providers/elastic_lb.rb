include Opscode::Aws::Elb

action :register do
  converge_by("add the node to ELB #{new_resource.elb_name}") do
    target_lb = elb.describe_load_balancers[:load_balancer_descriptions].find { |lb| lb[:load_balancer_name] == new_resource.elb_name }
    unless target_lb[:instances].detect { |instances| instances.include?(instance_id) }
      Chef::Log.info("Adding node to ELB #{new_resource.elb_name}")
      elb.register_instances_with_load_balancer(load_balancer_name: new_resource.elb_name, instances: [{ instance_id: instance_id }])
    else
      Chef::Log.debug("Node #{instance_id} is already present in ELB instances, no action required.")
    end
  end
end

action :deregister do
  converge_by("remove the node from ELB #{new_resource.elb_name}") do
    target_lb = elb.describe_load_balancers[:load_balancer_descriptions].find { |lb| lb[:load_balancer_name] == new_resource.elb_name }
    if target_lb[:instances].detect { |instances| instances.include?(instance_id) }
      Chef::Log.info("Removing node from ELB #{new_resource.elb_name}")
      elb.deregister_instances_from_load_balancer(load_balancer_name: new_resource.elb_name, instances: [{ instance_id: instance_id }])
    else
      Chef::Log.debug("Node #{instance_id} is not present in ELB instances, no action required.")
    end
  end
end

action :modify_attributes do
  if compare_attributes
    new_attributes = {}

    # Idle timeout
    if !@new_resource.idle_timeout.nil?
      new_attributes[:connection_settings] = {:idle_timeout => @new_resource.idle_timeout}
    end

    # Cross Zone Load Balancing
    if !@new_resource.cross_zone.nil?
      new_attributes[:cross_zone_load_balancing] = {:enabled => @new_resource.cross_zone}
    end

    # Access logs
    if !@new_resource.enable_access_log.nil?
      new_attributes[:access_log] = {
        :enabled => @new_resource.enable_access_log
      }

      # Only setting additional parameters when enable=true
      if @new_resource.enable_access_log
        new_attributes[:access_log][:emit_interval] = @new_resource.log_emit_interval
        new_attributes[:access_log][:s3_bucket_name] = @new_resource.log_s3_bucket_name
        new_attributes[:access_log][:s3_bucket_prefix] = @new_resource.log_s3_bucket_prefix
      end
    end
    converge_by("Modifying load balancer attributes #{new_attributes}") do
        Chef::Log.info("Changing connection idle timeout from #{@current_resource.idle_timeout}s \
        to #{@new_resource.idle_timeout}s")
        elb.modify_load_balancer_attributes({
          load_balancer_name: @new_resource.elb_name,
          load_balancer_attributes: new_attributes
        })
    end
  else
    Chef::Log.debug "#{@new_resource.elb_name} doesn't require modifications"
  end
end


def load_current_resource
  @current_resource = Chef::Resource::AwsElasticLb.new(@new_resource.name)
  @current_resource.name(@new_resource.name)
  @current_resource.elb_name(@new_resource.elb_name)

  # Fetching attributes
  attrs = elb.describe_load_balancer_attributes({load_balancer_name: @current_resource.elb_name})
  if attrs[:load_balancer_attributes]
    t = attrs[:load_balancer_attributes][:connection_settings]
    @current_resource.idle_timeout = t[:idle_timeout] if t

    t = attrs[:load_balancer_attributes][:cross_zone_load_balancing]
    @current_resource.cross_zone = t[:enabled] if t

    t = attrs[:load_balancer_attributes][:access_log]
    if t
      @current_resource.enable_access_log = t[:enabled]
      if t[:enabled]
        @current_resource.log_emit_interval = t[:emit_interval]
        @current_resource.log_s3_bucket_name = t[:s3_bucket_name]
        @current_resource.log_s3_bucket_prefix = t[:s3_bucket_prefix]
      end
    end

  end
end

def compare_attributes
  changed = [ :idle_timeout, :cross_zone, :enable_access_log ].select do |attrib|
    !@new_resource.send(attrib).nil? && @new_resource.send(attrib) != @current_resource.send(attrib)
  end

  changed += [ :log_emit_interval, :log_s3_bucket_name, :log_s3_bucket_prefix ].select do |attrib|
    !@new_resource.send(attrib).nil? && @new_resource.send(attrib) != @current_resource.send(attrib)
  end if changed.include?(:enable_access_log)

  changed.any?
end
