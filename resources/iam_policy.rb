default_action :create
actions :create, :delete

attribute :policy_name, kind_of: String, name_attribute: true
attribute :path, kind_of: String, default: '/'
attribute :policy_document, kind_of: String, required: true
attribute :account_id, kind_of: String, default: nil
# AWS common attributes
attribute :region, kind_of: String, default: nil
attribute :aws_access_key, kind_of: String, default: nil
attribute :aws_secret_access_key, kind_of: String, default: nil
attribute :aws_session_token, kind_of: String, default: nil
