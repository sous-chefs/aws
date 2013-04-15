actions :create, :delete

attribute :aws_access_key,               :kind_of => String
attribute :aws_secret_access_key,        :kind_of => String
attribute :rds_id,                       :kind_of => String
attribute :master_username,              :kind_of => String
attribute :master_user_password,         :kind_of => String
attribute :instance_class,               :kind_of => ['db.m1.small', 'db.m1.large', 'db.m1.xlarge', 'db.m2.2xlarge', 'db.m2.2xlarge', 'db.m2.4xlarge'], :default => 'db.m1.small'
attribute :allocated_storage,            :kind_of => Integer, :default => 25
attribute :engine,                       :kind_of => String, :default => 'mysql'
attribute :endpoint_port,                :kind_of => String
attribute :db_name,                      :kind_of => String
attribute :availability_zone,            :kind_of => String
attribute :multi_az,                     :kind_of => [TrueClass, FalseClass], :default => false
attribute :preferred_maintenance_window, :kind_of => String
attribute :backup_retention_period,      :kind_of => String
attribute :preferred_backup_window,      :kind_of => String
attribute :db_parameter_group,           :kind_of => String
attribute :engine_version,               :kind_of => String
attribute :auto_minor_version_upgrade,   :kind_of => [TrueClass, FalseClass], :default => false
attribute :license_model,                :kind_of => ['bring-your-own-license', 'license-included', 'general-public-license'], :default => 'general-public-license'
attribute :timeout,                      :kind_of => Integer, :default => 10*60 # 10 mins, nil or 0 for no timeout

def initialize(*args)
  super
  @action = :create
end
