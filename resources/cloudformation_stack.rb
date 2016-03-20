default_action :create
actions :create, :delete

attribute :stack_name, kind_of: String, name_attribute: true
# location of the template body, located in the "files" cookbook dir
attribute :template_source, kind_of: String, required: true
attribute :parameters, kind_of: Array, default: []
attribute :disable_rollback, kind_of: [TrueClass, FalseClass], default: false
attribute :iam_capability, kind_of: [TrueClass, FalseClass], default: false
attribute :stack_policy_body, kind_of: String
attribute :region, kind_of: String

# aws credential attributes
attribute :aws_access_key, kind_of: String
attribute :aws_secret_access_key, kind_of: String
attribute :aws_session_token, kind_of: String
attribute :aws_assume_role_arn, kind_of: String
attribute :aws_role_session_name, kind_of: String
