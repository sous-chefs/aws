actions :assign, :unassign
default_action :assign

state_attrs :aws_access_key,
            :ip,
            :interface,
            :timeout

attribute :aws_access_key,        kind_of: String
attribute :aws_secret_access_key, kind_of: String
attribute :aws_session_token,     kind_of: String
attribute :aws_assume_role_arn,   kind_of: String
attribute :aws_role_session_name, kind_of: String
attribute :region,                kind_of: String
attribute :ip,                    kind_of: String
attribute :interface,             kind_of: String
attribute :timeout,               default: 3 * 60 # 3 mins, nil or 0 for no timeout
