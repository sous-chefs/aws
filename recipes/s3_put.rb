include_recipe "aws"

aws_s3_put "/etc/rsyslog.conf" do
	aws_access_key ""
	aws_secret_key ""
	bucket ""
	path "/files/rsyslog.conf"
	action :put
end
