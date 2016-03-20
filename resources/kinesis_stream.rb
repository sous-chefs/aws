default_action :create
actions :create, :delete

attribute :stream_name, kind_of: String, name_attribute: true
attribute :starting_shard_count, kind_of: Integer, required: true
# AWS common attributes
attribute :region, kind_of: String
attribute :aws_access_key, kind_of: String
attribute :aws_secret_access_key, kind_of: String
attribute :aws_session_token, kind_of: String
