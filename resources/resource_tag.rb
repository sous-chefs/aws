actions :add, :update, :remove, :force_remove
default_action :update

state_attrs :aws_access_key,
            :resource_id,
            :tags

attribute :aws_access_key, kind_of: String
attribute :aws_secret_access_key, kind_of: String
attribute :aws_session_token,     kind_of: String, default: nil
attribute :resource_id,  kind_of: [String, Array], regex: /(i|snap|vol)-[a-fA-F0-9]{8}/
attribute :tags, kind_of: Hash, required: true
