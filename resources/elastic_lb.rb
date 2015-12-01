actions :register, :deregister
default_action :register
state_attrs :aws_access_key,
            :elb_name

identity_attr :elb_name

attribute :aws_access_key,        kind_of: String
attribute :aws_secret_access_key, kind_of: String
attribute :aws_session_token,     kind_of: String, default: nil
attribute :elb_name,                  kind_of: String, name_attribute: true
attribute :idle_timeout,          kind_of: Integer
attribute :cross_zone,            kind_of: [ TrueClass, FalseClass ]
attribute :enable_access_log,     kind_of: [ TrueClass, FalseClass ]
attribute :log_emit_interval,     kind_of: Integer, equal_to: [5, 60]
attribute :log_s3_bucket_name,    kind_of: String
attribute :log_s3_bucket_prefix,  kind_of: String
