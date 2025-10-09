resource_name :aws_route53_record
provides :aws_route53_record
unified_mode true
provides :route53_record # for compatibility with the old cookbook

property :value,                       [String, Array]
property :type,                        String, required: true
property :ttl,                         Integer, default: 3600
property :weight,                      String
property :record_name,                 String
property :set_identifier,              String
property :geo_location,                String
property :geo_location_country,        String
property :geo_location_continent,      String
property :geo_location_subdivision,    String
property :zone_id,                     String
property :zone_name,                   String
property :overwrite,                   [true, false], default: true
property :alias_target,                Hash
property :mock,                        [true, false], default: false
property :fail_on_error,               [true, false], default: false

# authentication
property :aws_access_key,        String
property :aws_secret_access_key, String, sensitive: true
property :aws_session_token,     String, sensitive: true
property :aws_assume_role_arn,   String
property :aws_role_session_name, String
property :region,                String, default: lazy { fallback_region }

include AwsCookbook::Ec2 # needed for aws_region helper

# allow use of the property names from the route53 cookbook
alias_method :aws_access_key_id, :aws_access_key
alias_method :aws_region, :region

action :create do
  if current_resource_record_set == resource_record_set
    Chef::Log.info "Record has not changed, skipping: #{name}[#{type}]"
  elsif overwrite?
    change_record 'UPSERT'
    Chef::Log.info "Record created/modified: #{name}[#{type}]"
  else
    change_record 'CREATE'
    Chef::Log.info "Record created: #{name}[#{type}]"
  end
end

action :delete do
  if mock?
    # Make some fake data so that we can successfully delete when testing.
    mock_resource_record_set = {
      name: 'pdb_test.example.com.',
      type: 'A',
      ttl: 300,
      resource_records: [{ value: '192.168.1.2' }],
    }

    route53_client.stub_responses(
      :list_resource_record_sets,
      resource_record_sets: [mock_resource_record_set],
      is_truncated: false,
      max_items: 1
    )
  end

  if current_resource_record_set.nil?
    Chef::Log.info 'There is nothing to delete.'
  else
    change_record 'DELETE'
    Chef::Log.info "Record deleted: #{name}"
  end
end

action_class do
  include AwsCookbook::Ec2

  # convert the passed name to the trailing period format
  def name
    @name ||= new_resource.name.last == '.' ? new_resource.name : "#{new_resource.name}."
  end

  def record_name
    if new_resource.record_name
      @record_name ||= new_resource.record_name.last == '.' ? new_resource.record_name : "#{new_resource.record_name}."
    end
  end

  def fqdn
    @fqdn = record_name || name
  end

  def value
    @value ||= Array(new_resource.value)
  end

  def type
    @type ||= new_resource.type
  end

  def ttl
    @ttl ||= new_resource.ttl
  end

  def geo_location_country
    @geo_location_country ||= new_resource.geo_location_country
  end

  def geo_location_continent
    @geo_location_continent ||= new_resource.geo_location_continent
  end

  def geo_location_subdivision
    @geo_location_subdivision ||= new_resource.geo_location_subdivision
  end

  def geo_location
    if geo_location_country
      { country_code: geo_location_country }
    elsif geo_location_continent
      { continent_code: geo_location_continent }
    elsif geo_location_subdivision
      { country_code: geo_location_country, subdivision_code: geo_location_subdivision }
    else
      @geo_location ||= new_resource.geo_location
    end
  end

  def set_identifier
    @set_identifier ||= new_resource.set_identifier
  end

  def overwrite?
    @overwrite ||= new_resource.overwrite
  end

  def alias_target
    @alias_target ||= new_resource.alias_target
  end

  def mock?
    @mock ||= new_resource.mock
  end

  def zone_name
    @zone_name ||= new_resource.zone_name
  end

  def zone_id
    @zone_id ||= new_resource.zone_id
  end

  # find the zone ID by zone name
  def zone_id_from_name(name)
    route53_client.list_hosted_zones_by_name(dns_name: name).hosted_zones.collect { |x| x.id if x.name == name }.first
  end

  def fail_on_error
    @fail_on_error ||= new_resource.fail_on_error
  end

  def route53_client
    @route53 ||= begin
      require 'aws-sdk-route53'
      Chef::Log.debug('Initializing Aws::Route53::Client')
      create_aws_interface(::Aws::Route53::Client, region: new_resource.region, mock: new_resource.mock)
    end
  end

  def resource_record_set
    rr_set = {
      name: fqdn,
      type: type,
    }
    if alias_target
      rr_set[:alias_target] = alias_target
      rr_set[:set_identifier] = set_identifier
      rr_set[:geo_location] = geo_location
    elsif geo_location
      rr_set[:set_identifier] = set_identifier
      rr_set[:geo_location] = geo_location
      rr_set[:ttl] = ttl
      rr_set[:resource_records] = value.sort.map { |v| { value: v } }
    else
      rr_set[:ttl] = ttl
      rr_set[:resource_records] = value.sort.map { |v| { value: v } }
    end
    rr_set
  end

  def current_resource_record_set
    # List all the resource records for this zone:
    lrrs = route53_client
           .list_resource_record_sets(
             hosted_zone_id: zone_id ? "/hostedzone/#{zone_id}" : zone_id_from_name(zone_name),
             start_record_name: fqdn
           )

    # Select current resource record set by name and geo location.
    current = lrrs[:resource_record_sets]
              .select { |rr| rr[:name] == fqdn && rr[:type] == type && rr[:geo_location].to_h == geo_location.to_h }.first

    # return as hash, converting resource record
    # array of structs to array of hashes
    if current
      crr_set = {
        name: current[:name],
        type: current[:type],
      }
      if current[:alias_target]
        crr_set[:alias_target] = current[:alias_target].to_h
        crr_set[:alias_target][:dns_name] = current[:alias_target][:dns_name].chomp('.')
      end
      crr_set[:ttl] = current[:ttl] unless current[:ttl].nil?
      crr_set[:resource_records] = current[:resource_records].sort_by(&:value).map(&:to_h) unless current[:resource_records].empty?
      if current[:geo_location]
        crr_set[:set_identifier] = current[:set_identifier]
        crr_set[:geo_location] = current[:geo_location].to_h
      end

      crr_set
    else
      {}
    end
  end

  def change_record(action)
    request = {
      hosted_zone_id: zone_id ? "/hostedzone/#{zone_id}" : zone_id_from_name(zone_name),
      change_batch: {
        comment: "Chef Route53 Resource: #{name}",
        changes: [
          {
            action: action,
            resource_record_set: resource_record_set,
          },
        ],
      },
    }
    converge_by("#{action} record #{new_resource.name} ") do
      response = route53_client.change_resource_record_sets(request)
      Chef::Log.debug "Changed record - #{action}: #{response.inspect}"
    end
  rescue Aws::Route53::Errors::ServiceError => e
    raise if fail_on_error
    Chef::Log.error "Error with #{action}request: #{request.inspect} ::: "
    Chef::Log.error e.message
  end
end
