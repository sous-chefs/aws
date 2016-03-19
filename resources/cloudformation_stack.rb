default_action :create
actions :create, :delete

attribute :stack_name, kind_of: String, name_attribute: true
# location of the template body, located in the "files" cookbook dir
attribute :template_source, kind_of: String, required: true
attribute :parameters, kind_of: Array, default: []
attribute :disable_rollback, kind_of: TrueClass, default: false
attribute :iam_capability, kind_of: TrueClass, default: false
attribute :stack_policy_body, kind_of: String, default: nil
attribute :region, kind_of: String, default: nil
attribute :aws_access_key, kind_of: String, default: nil
attribute :aws_secret_access_key, kind_of: String, default: nil
attribute :aws_session_token, kind_of: String, default: nil
