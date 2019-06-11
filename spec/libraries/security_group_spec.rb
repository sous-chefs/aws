require 'spec_helper'
require_relative '../../libraries/security_group'

describe AwsCookbook::SecurityGroup do
  it 'should remove empty arrays from hash' do
    # Arrange
    ip_permissions = [{ from_port: 2222,
                        ip_protocol: 'tcp',
                        ip_ranges: [{ cidr_ip: '10.10.10.0/24',
                                      description: 'SSH access from the office' }],
                        ipv_6_ranges: [],
                        prefix_list_ids: [],
                        to_port: 2222,
                        user_id_group_pairs: [] }]

    expected = [{ from_port: 2222,
                  ip_protocol: 'tcp',
                  ip_ranges: [{ cidr_ip: '10.10.10.0/24',
                                description: 'SSH access from the office' }],
                  to_port: 2222 }]

    # Act
    actual = AwsCookbook::SecurityGroup.normalize_hash_ip_permissions(ip_permissions)

    # Assert
    expect(actual).to eq(expected)
  end
end
