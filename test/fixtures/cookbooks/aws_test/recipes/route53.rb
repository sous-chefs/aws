aws_route53_zone 'Add testkitchen.dmz zone' do
  name 'testkitchen.dmz'
  description 'A test zone created by Test Kitchen. Delete anytime.'
  aws_access_key node['aws_test']['key_id']
  aws_secret_access_key node['aws_test']['access_key']
  aws_session_token node['aws_test']['session_token']
end

aws_route53_record "Add our node's record" do
  name 'chefnode.testkitchen.dmz'
  value node['ipaddress']
  type 'A'
  ttl 3600
  zone_name 'testkitchen.dmz.'
  overwrite true
  aws_access_key node['aws_test']['key_id']
  aws_secret_access_key node['aws_test']['access_key']
  aws_session_token node['aws_test']['session_token']
end

# aws_route53_record "Add our node's alias record" do
#   name 'chefnode-alias.testkitchen.dmz'
#   alias_target 'chefnode-alias.testkitchen.dmz'
#   type 'A'
#   zone_name 'testkitchen.dmz.'
#   overwrite true
#   aws_access_key node['aws_test']['key_id']
#   aws_secret_access_key node['aws_test']['access_key']
# end

# aws_route53_record "Delete our node's record" do
#   name 'chefnode-alias.testkitchen.dmz'
#   zone_name 'testkitchen.dmz.'
#   action :delete
#   aws_access_key node['aws_test']['key_id']
#   aws_secret_access_key node['aws_test']['access_key']
# end

aws_route53_record "Delete our node's record" do
  name 'chefnode.testkitchen.dmz'
  zone_name 'testkitchen.dmz.'
  type 'A'
  value node['ipaddress']
  action :delete
  aws_access_key node['aws_test']['key_id']
  aws_secret_access_key node['aws_test']['access_key']
  aws_session_token node['aws_test']['session_token']
end

aws_route53_zone 'Delete testkitchen.dmz zone' do
  name 'testkitchen.dmz'
  aws_access_key node['aws_test']['key_id']
  aws_secret_access_key node['aws_test']['access_key']
  aws_session_token node['aws_test']['session_token']
  action :delete
end
