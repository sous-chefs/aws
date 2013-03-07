actions :auto_attach

attribute :mount_point,        :kind_of => String
attribute :disk_count,         :kind_of => Integer
attribute :disk_size,          :kind_of => Integer
attribute :level,              :default => 10
attribute :filesystem,         :default => "ext4"
attribute :filesystem_options, :default => "rw,noatime,nobootwait"
attribute :snapshots,          :default => []
attribute :disk_type,          :kind_of => String, :default => 'standard'
attribute :disk_piops,         :kind_of => Integer, :default => 0

