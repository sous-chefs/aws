# frozen_string_literal: true

name 'aws-agents'
run_list 'test::agents'
named_run_list :remove, 'test::remove'
cookbook 'aws', path: '.'
cookbook 'test', path: 'test/cookbooks/test'
cookbook 'aws_test', path: 'test/fixtures/cookbooks/aws_test'
