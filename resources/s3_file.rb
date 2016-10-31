actions :create, :create_if_missing, :touch, :delete
default_action :create

state_attrs :aws_access_key,
            :backup,
            :bucket,
            :checksum,
            :group,
            :mode,
            :owner,
            :path,
            :remote_path

attribute :path, kind_of: String, name_attribute: true
attribute :remote_path, kind_of: String
attribute :region, kind_of: [String, NilClass]
attribute :bucket, kind_of: String
attribute :aws_access_key, kind_of: String
attribute :aws_secret_access_key, kind_of: String
attribute :aws_session_token, kind_of: String
attribute :aws_assume_role_arn, kind_of: String
attribute :aws_role_session_name, kind_of: String
attribute :owner, regex: Chef::Config[:user_valid_regex]
attribute :group, regex: Chef::Config[:group_valid_regex]
attribute :mode, kind_of: [String, NilClass]
attribute :checksum, kind_of: [String, NilClass]
attribute :backup, kind_of: [Integer, FalseClass], default: 5
attribute :headers, kind_of: Hash
attribute :use_etag, kind_of: [TrueClass, FalseClass], default: true
attribute :use_last_modified, kind_of: [TrueClass, FalseClass], default: true
attribute :atomic_update, kind_of: [TrueClass, FalseClass], default: true
attribute :force_unlink, kind_of: [TrueClass, FalseClass], default: false
attribute :manage_symlink_source, kind_of: [TrueClass, FalseClass]
attribute :sensitive, kind_of: [TrueClass, FalseClass], default: false
attribute :retries, kind_of: Integer, default: 0
attribute :retry_delay, kind_of: Integer, default: 3
if node['platform_family'] == 'windows'
  attribute :inherits, kind_of: [TrueClass, FalseClass], default: true
  attribute :rights, kind_of: Hash
end

# allow use of the old aws_access_key_id property
alias_method :aws_access_key_id, :aws_access_key
