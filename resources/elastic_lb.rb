actions :register, :deregister

default_action :register

attribute :aws_access_key,        :kind_of => String
attribute :aws_secret_access_key, :kind_of => String
attribute :name,                  :kind_of => String
