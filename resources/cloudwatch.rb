default_action :create
actions :create, :delete, :disable_action, :enable_action

attribute :alarm_name, kind_of: String, name_attribute: true
attribute :alarm_description, kind_of: String
attribute :actions_enabled, kind_of: TrueClass
attribute :ok_actions, kind_of: Array, default: []
attribute :alarm_actions, kind_of: Array, default: []
attribute :insufficient_data_actions, kind_of: Array, default: []
attribute :metric_name, kind_of: String
attribute :namespace, kind_of: String
attribute :statistic, equal_to: %w(SampleCount Average Sum Minimum Maximum)
attribute :extended_statistic, kind_of: String
attribute :dimensions, Array, default: []
attribute :period, kind_of: Integer
attribute :unit, kind_of: String
attribute :evaluation_periods, kind_of: Integer
attribute :threshold, kind_of: [Float, Integer]
attribute :comparison_operator, equal_to: %w(GreaterThanOrEqualToThreshold GreaterThanThreshold LessThanThreshold LessThanOrEqualToThreshold)

# aws credential/connection attributes
attribute :region, kind_of: String
attribute :aws_access_key, kind_of: String
attribute :aws_secret_access_key, kind_of: String
attribute :aws_session_token, kind_of: String
attribute :aws_assume_role_arn, kind_of: String
attribute :aws_role_session_name, kind_of: String
