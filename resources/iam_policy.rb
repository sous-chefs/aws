default_action :create
actions :create, :delete

attribute :policy_name, kind_of: String, name_attribute: true
attribute :path, kind_of: String, default: '/'
attribute :policy_document, kind_of: String, required: true
attribute :account_id, kind_of: String
attribute :region, kind_of: String

# aws credential attributes
attribute :aws_access_key, kind_of: String
attribute :aws_secret_access_key, kind_of: String
attribute :aws_session_token, kind_of: String
attribute :aws_assume_role_arn, kind_of: String
attribute :aws_role_session_name, kind_of: String
