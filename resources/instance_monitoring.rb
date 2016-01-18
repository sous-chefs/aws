actions :enable, :disable
default_action :enable

state_attrs :aws_access_key

attribute :aws_access_key, kind_of: String
attribute :aws_secret_access_key, kind_of: String
attribute :aws_session_token,     kind_of: String, default: nil
