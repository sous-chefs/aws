node.default['route53']['zone_id'] = 'Z2DEMODEMODEMO'

node.default['records']['generic_record']['name'] = 'kitchen-test.yourdomain.org'
node.default['records']['generic_record']['value'] = '16.8.4.3'
node.default['records']['generic_record']['type'] = 'A'
node.default['records']['generic_record']['ttl'] = 3600

node.default['records']['alias_record']['name'] = 'kitchen-test-alias.yourdomain.org'
node.default['records']['alias_record']['alias_target']['dns_name'] = 'dns-name'
node.default['records']['alias_record']['alias_target']['hosted_zone_id'] = 'host-zone-id'
node.default['records']['alias_record']['alias_target']['evaluate_target_health'] = false
node.default['records']['alias_record']['type'] = 'A'
node.default['records']['alias_record']['run'] = true

aws_route53_record node['records']['generic_record']['name'] do
  value                 node['records']['generic_record']['value']
  type                  node['records']['generic_record']['type']
  ttl                   node['records']['generic_record']['ttl']
  zone_id               node['route53']['zone_id']
  aws_access_key        node['aws_test']['key_id']
  aws_secret_access_key node['aws_test']['access_key']
  overwrite             true
  action                :create
  mock                  true
end

aws_route53_record node['records']['alias_record']['name'] do
  alias_target          node['records']['alias_record']['alias_target']
  type                  node['records']['alias_record']['type']
  zone_id               node['route53']['zone_id']
  aws_access_key        node['aws_test']['key_id']
  aws_secret_access_key node['aws_test']['access_key']
  overwrite             true
  action                :create
  only_if               { node['records']['alias_record']['run'] }
  mock                  true
end

aws_route53_record "#{node['records']['generic_record']['name']}_delete" do
  name                  node['records']['generic_record']['name']
  value                 node['records']['generic_record']['value']
  type                  node['records']['generic_record']['type']
  zone_id               node['route53']['zone_id']
  aws_access_key        node['aws_test']['key_id']
  aws_secret_access_key node['aws_test']['access_key']
  action                :delete
  mock                  true
end
