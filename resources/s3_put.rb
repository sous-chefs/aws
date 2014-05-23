actions :put

attribute :aws_access_key, 	:kind_of => String
attribute :aws_secret_key, 	:kind_of => String
attribute :bucket, 		:kind_of => String
attribute :path, 		:kind_of => String
attribute :source,		:kind_of => String, :name_attribute => true

def initialize(*args)
	super
	@action = :put
	@source = name
end
