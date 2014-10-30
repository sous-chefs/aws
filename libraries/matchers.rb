if defined?(ChefSpec)
  def create_aws_ebs_volume(vol_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aws_ebs_volume, :create, vol_name)
  end

  def attach_aws_ebs_volume(vol_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aws_ebs_volume, :attach, vol_name)
  end

  def detach_aws_ebs_volume(vol_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aws_ebs_volume, :detach, vol_name)
  end

  def prune_aws_ebs_volume(vol_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aws_ebs_volume, :prune, vol_name)
  end

  def associate_aws_elastic_ip(eip_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aws_elastic_ip, :associate, eip_name)
  end

  def dissociate_aws_elastic_ip(eip_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aws_elastic_ip, :dissociate, eip_name)
  end

  def register_aws_elastic_lb(elb_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aws_elastic_lb, :register, elb_name)
  end

  def deregister_aws_elastic_lb(elb_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aws_elastic_lb, :deregister, elb_name)
  end

  def add_aws_resource_tag(tag_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aws_resource_tag, :add, tag_name)
  end

  def update_aws_resource_tag(tag_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aws_resource_tag, :update, tag_name)
  end

  def remove_aws_resource_tag(tag_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aws_resource_tag, :remove, tag_name)
  end

  def force_remove_aws_resource_tag(tag_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aws_resource_tag, :force_remove, tag_name)
  end
end
