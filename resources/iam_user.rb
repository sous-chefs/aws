default_action :create
actions :create, :delete

attribute :user_name, kind_of: String, name_attribute: true
attribute :path, kind_of: String, default: '/'
# AWS common attributes
attribute :region, kind_of: String, default: nil
attribute :aws_access_key, kind_of: String, default: nil
attribute :aws_secret_access_key, kind_of: String, default: nil
attribute :aws_session_token, kind_of: String, default: nil
