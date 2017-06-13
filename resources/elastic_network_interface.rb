actions :attach, :detach, :create

state_attrs :aws_access_key,
            :network_interface_id,
            :device_index,
            :subnet_id,
            :private_ip_addresses,
            :groups,
            :timeout

attribute :aws_access_key,        kind_of: String
attribute :aws_secret_access_key, kind_of: String
attribute :network_interface_id,  kind_of: String, name_attribute: true
attribute :device_index,          kind_of: String
attribute :subnet_id,             kind_of: String
attribute :private_ip_addresses,  kind_of: Array
attribute :groups,                kind_of: Array
attribute :timeout,               default: 3 * 60 # 3 mins, nil or 0 for no timeout

def initialize(*args)
  super
  @action = :attach
end
