def initialize(*args)
  super
  @action = :update
end

actions :add, :update, :remove, :force_remove

attribute :aws_access_key, :kind_of => String, :required => true
attribute :aws_secret_access_key, :kind_of => String, :required => true
attribute :resource_id,  :kind_of => [ String, Array ], :regex => /(i|snap|vol)-[a-zA-Z0-9]+/
attribute :tags, :kind_of => Hash, :required => true
