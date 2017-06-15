property :alarm_name, String, name_property: true
property :alarm_description, String
property :actions_enabled, true
property :ok_actions, Array, default: []
property :alarm_actions, Array, default: []
property :insufficient_data_actions, Array, default: []
property :metric_name, String
property :namespace, String
property :statistic, equal_to: %w(SampleCount Average Sum Minimum Maximum)
property :extended_statistic, String
property :dimensions, Array, default: []
property :period, Integer
property :unit, String
property :evaluation_periods, Integer
property :threshold, [Float, Integer]
property :comparison_operator, equal_to: %w(GreaterThanOrEqualToThreshold GreaterThanThreshold LessThanThreshold LessThanOrEqualToThreshold)

# authentication
property :region, String, default: lazy { fallback_region }
property :aws_access_key, String
property :aws_secret_access_key, String
property :aws_session_token, String
property :aws_assume_role_arn, String
property :aws_role_session_name, String

include AwsCookbook::Ec2 # needed for aws_region helper

# Create action will fire put_metric_alarm of cloudwatch API, will update the alarm if found changes in parameters.
action :create do
  if cwh_if_changed('any')
    converge_by("create/update metric #{new_resource.alarm_name}") do
      options = build_cwh_options
      cwh.put_metric_alarm(options)
    end
  else
    Chef::Log.debug("No action required for metric #{new_resource.alarm_name}")
  end
end

# Delete action will fire delete_alarms of cloudwatch API.
action :delete do
  converge_by("delete metric #{new_resource.alarm_name}") do
    options = { alarm_names: [new_resource.alarm_name] }
    cwh.delete_alarms(options)
  end
end

# Disable action will fire disable_alarm_actions of cloudwatch API. if not disabled already.
action :disable_action do
  if cwh_if_changed('alarm_action', 'false')
    converge_by("disable alarm action metric #{new_resource.alarm_name}") do
      options = { alarm_names: [new_resource.alarm_name] }
      cwh.disable_alarm_actions(options)
    end
  else
    Chef::Log.debug("No action required for metric #{new_resource.alarm_name}")
  end
end

# Enable action will fire disable_alarm_actions of cloudwatch API. if not enabled already.
action :enable_action do
  if cwh_if_changed('alarm_action', 'true')
    converge_by("enable alarm action metric #{new_resource.alarm_name}") do
      options = { alarm_names: [new_resource.alarm_name] }
      cwh.enable_alarm_actions(options)
    end
  else
    Chef::Log.debug("No action required for metric #{new_resource.alarm_name}")
  end
end

action_class do
  include AwsCookbook::Ec2

  def cwh
    require 'aws-sdk'
    Chef::Log.debug('Initializing the CloudWatch Client')
    @cwh ||= create_aws_interface(::Aws::CloudWatch::Client, region: new_resource.region)
  end

  # Make options for cloudwatch API
  def build_cwh_options
    options = {
      alarm_name: new_resource.alarm_name,
      period: new_resource.period,
      evaluation_periods: new_resource.evaluation_periods,
      threshold: new_resource.threshold.to_f,
      comparison_operator: new_resource.comparison_operator,
      metric_name: new_resource.metric_name,
      namespace: new_resource.namespace,
    }
    options[:alarm_description] = new_resource.alarm_description if new_resource.alarm_description
    if new_resource.actions_enabled
      if new_resource.ok_actions.empty? && new_resource.alarm_actions.empty? && new_resource.insufficient_data_actions.empty?
        raise 'No actions provided for any of OK/ALARM/INSUFFICIENT'
      else
        options[:actions_enabled] = true if new_resource.actions_enabled
        options[:ok_actions] = new_resource.ok_actions if new_resource.ok_actions.any?
        options[:alarm_actions] = new_resource.alarm_actions if new_resource.alarm_actions.any?
        options[:insufficient_data_actions] = new_resource.insufficient_data_actions if new_resource.insufficient_data_actions.any?
      end
    end
    options[:statistic] = new_resource.statistic if new_resource.statistic
    options[:dimensions] = new_resource.dimensions if new_resource.dimensions
    options[:extended_statistic] = new_resource.extended_statistic if new_resource.extended_statistic
    options[:unit] = new_resource.unit if new_resource.unit
    options
  end

  # Function to check if the alarm needs to be updated.
  # Params
  # type - any, alarm_action
  # p - boolen option for alarm_action
  def cwh_if_changed(type, *p)
    options = { alarm_names: [new_resource.alarm_name], max_records: 1 }
    resp = cwh.describe_alarms(options)
    if !resp.metric_alarms.empty?
      if type == 'any'
        new_params = build_cwh_options
        new_params.each_key do |k|
          if resp.metric_alarms[0][k].nil? || resp.metric_alarms[0][k].to_s.empty?
            return true
          elsif new_params[k].is_a?(Array) || resp.metric_alarms[0][k].is_a?(Array)
            if new_params[k].length != resp.metric_alarms[0][k].length
              return true
            else
              new_params[k].each_index do |n|
                if resp.metric_alarms[0][k][n].nil? || resp.metric_alarms[0][k][n].to_s.empty?
                  return true
                elsif new_params[k][n].is_a?(Hash) || resp.metric_alarms[0][k][n].is_a?(Hash)
                  if new_params[k][n].length != resp.metric_alarms[0][k][n].length
                    return true
                  else
                    new_params[k][n].each_key { |m| return true unless resp.metric_alarms[0][k][n][m].nil? || resp.metric_alarms[0][k][n][m].to_s.empty? || new_params[k][n][m] == resp.metric_alarms[0][k][n][m] }
                  end
                else
                  return true unless resp.metric_alarms[0][k][n].nil? || resp.metric_alarms[0][k][n].to_s.empty? || new_params[k][n] == resp.metric_alarms[0][k][n]
                end
              end
            end
          else
            return true unless new_params[k] == resp.metric_alarms[0][k]
          end
        end
      elsif type == 'alarm_action'
        return true unless resp.metric_alarms[0].actions_enabled.to_s == p.join
      end
      false
    else
      true
    end
  end
end
