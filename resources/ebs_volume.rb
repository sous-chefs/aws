actions :create, :attach, :detach, :snapshot, :prune
default_action :create

state_attrs :availability_zone,
            :aws_access_key,
            :description,
            :device,
            :most_recent_snapshot,
            :piops,
            :size,
            :snapshot_id,
            :snapshots_to_keep,
            :timeout,
            :volume_id,
            :volume_type,
            :encrypted,
            :delete_on_termination

attribute :aws_access_key,        kind_of: String
attribute :aws_secret_access_key, kind_of: String
attribute :aws_session_token,     kind_of: String
attribute :aws_assume_role_arn,   kind_of: String
attribute :aws_role_session_name, kind_of: String
attribute :region,                kind_of: String
attribute :size,                  kind_of: Integer
attribute :snapshot_id,           kind_of: String
attribute :most_recent_snapshot,  kind_of: [TrueClass, FalseClass], default: false
attribute :availability_zone,     kind_of: String
attribute :device,                kind_of: String
attribute :volume_id,             kind_of: String
attribute :description,           kind_of: String
attribute :timeout,               default: 3 * 60 # 3 mins, nil or 0 for no timeout
attribute :snapshots_to_keep,     default: 2
attribute :volume_type,           kind_of: String, default: 'standard'
attribute :piops,                 kind_of: Integer, default: 0
attribute :encrypted,             kind_of: [TrueClass, FalseClass], default: false
attribute :kms_key_id,            kind_of: String
attribute :delete_on_termination, kind_of: [TrueClass, FalseClass], default: false
