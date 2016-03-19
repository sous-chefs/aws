default_action :create
actions :create, :delete

attribute :group_name, kind_of: String, name_attribute: true
attribute :path, kind_of: String, default: '/'
attribute :members, kind_of: Array, default: []
attribute :remove_members, kind_of: TrueClass, default: true
attribute :policy_members, kind_of: Array, default: []
attribute :remove_policy_members, kind_of: TrueClass, default: true
# AWS common attributes
attribute :region, kind_of: String, default: nil
attribute :aws_access_key, kind_of: String, default: nil
attribute :aws_secret_access_key, kind_of: String, default: nil
attribute :aws_session_token, kind_of: String, default: nil
