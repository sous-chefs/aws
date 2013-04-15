include Opscode::Aws::Rds
include Opscode::OpenSSL::Password

# Support whyrun
def whyrun_supported?
  true
end

action :delete do
  Chef::Log.info("Deleting RDS instance #{new_resource.rds_id}.")
  converge_by("delete an RDS instance with id=#{new_resource.rds_id}") do
    rds.delete_db_instance(new_resource.rds_id)
  end
end

action :create do
  raise "Cannot create a RDS instance without a specific name" unless new_resource.rds_id

  raise "Please provided a master username" unless new_resource.master_username

  master_password = new_resource.master_user_password || secure_password

  converge_by("create an RDS instance with id=#{new_resource.rds_id} size=#{new_resource.allocated_storage} engine=#{new_resource.engine} and update the node data with created RDS information") do
    #Check if the RDS instance already exists, if so then just add the attributes to the node
    begin
      existing_rds = rds.describe_db_instances(new_resource.rds_id)
      update_node(existing_rds, master_password)
    rescue RightAws::AwsError
      Chef::Log.info("RDS instance #{new_resource.rds_id} doesn't exists.")
      new_rds = create_rds_instance(
          new_resource.rds_id,
          new_resource.master_username,
          master_password,
          new_resource.timeout,
          :instance_class => new_resource.instance_class,
          :allocated_storage => new_resource.allocated_storage,
          :engine => new_resource.engine,
          :endpoint_port => new_resource.endpoint_port,
          :db_name => new_resource.db_name,
          :availability_zone => new_resource.availability_zone,
          :multi_az => new_resource.multi_az,
          :preferred_maintenance_window => new_resource.preferred_maintenance_window,
          :backup_retention_period => new_resource.backup_retention_period,
          :preferred_backup_window => new_resource.preferred_backup_window,
          :db_parameter_group => new_resource.db_parameter_group,
          :engine_version => new_resource.engine_version,
          :auto_minor_version_upgrade => new_resource.auto_minor_version_upgrade,
          :license_model => new_resource.license_model
      )
      update_node(new_rds, master_password)
    end
  end
end

private

def update_node(rds_instance, master_password)
  node.set['aws']['rds'][new_resource.name]['rds_id'] = rds_instance[:aws_id]
  node.set['aws']['rds'][new_resource.name]['master_username'] = rds_instance[:master_username]
  node.set['aws']['rds'][new_resource.name]['master_user_password'] = master_password
  node.set['aws']['rds'][new_resource.name]['endpoint_address'] = rds_instance[:endpoint_address]
  node.set['aws']['rds'][new_resource.name]['endpoint_port'] = rds_instance[:endpoint_port]
  node.save unless Chef::Config[:solo]
end

def create_rds_instance(rds_instance_id, master_username, master_user_password, timeout, params = {})
  rds_instance = rds.create_db_instance(rds_instance_id, master_username, master_user_password, params)

  begin
    Timeout::timeout(timeout) do
      while true
        rds_instance = rds.describe_db_instances(rds_instance_id)
        if rds_instance.first[:status] == 'available'
          Chef::Log.info("RDS instance #{rds_instance_id} is available")
          break
        else
          Chef::Log.debug("RDS instance is #{rds_instance.first[:status]}")
        end
        sleep 10
      end
    end
  rescue Timeout::Error
    raise "Timed out waiting for RDS instance creation after #{timeout} seconds"
  end

  rds_instance.first
end
