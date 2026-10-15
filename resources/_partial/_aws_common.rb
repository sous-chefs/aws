# frozen_string_literal: true

property :region, String, default: lazy { fallback_region }
property :aws_access_key, String
property :aws_secret_access_key, String, sensitive: true
property :aws_session_token, String, sensitive: true
property :aws_assume_role_arn, String
property :aws_role_session_name, String
