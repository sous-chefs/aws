aws_route53_zone 'testkitchen.dmz' do
  description 'A test zone created by Test Kitchen. Delete anytime.'
  aws_access_key node['aws_test']['key_id']
  aws_secret_access_key node['aws_test']['access_key']
  aws_session_token node['aws_test']['session_token']
end

aws_route53_record 'chefnode.testkitchen.dmz' do
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

aws_route53_record 'chefnode.testkitchen.dmz' do
  zone_name 'testkitchen.dmz.'
  type 'A'
  value node['ipaddress']
  action :delete
  aws_access_key node['aws_test']['key_id']
  aws_secret_access_key node['aws_test']['access_key']
  aws_session_token node['aws_test']['session_token']
end

aws_route53_zone 'testkitchen.dmz' do
  aws_access_key node['aws_test']['key_id']
  aws_secret_access_key node['aws_test']['access_key']
  aws_session_token node['aws_test']['session_token']
  action :delete
end
