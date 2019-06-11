class Hash
  # Removes empty values from a hash
  def remove_empty
    p = proc do |*args|
      v = args.last
      v.delete_if(&p) if v.respond_to? :delete_if
      v.nil? || v.respond_to?(:"empty?") && v.empty?
    end
    delete_if(&p)
  end
end

module AwsCookbook
  module SecurityGroup
    # Removes keys which contain nil values and empty arrays
    # This will let us compare hashes and ignore nils
    #
    # @param ip_permissions [Array<Aws::EC2::Types::IpPermission>]
    def self.normalize_aws_types_ip_permissions(ip_permissions)
      ip_permissions.map { |i| i.to_h.remove_empty }
    end

    # Convert the chef array of hashes for ip_permissions to an actual AWS data structure
    # This will be beneficial since it will:
    # Automatically order/sort all keys
    # Initialize default values
    # Protect against compatibility problems if this class is ever updated
    #
    # @param ip_hash [Array<Hash>] ip_permissions from chef resource which maps to Aws::EC2::Types::IpPermission
    def self.normalize_hash_ip_permissions(ip_hash)
      require 'aws-sdk-ec2'
      ip_permissions = ip_hash.map { |i| Aws::EC2::Types::IpPermission.new(i).to_h }
      normalize_aws_types_ip_permissions(ip_permissions)
    end
  end
end
