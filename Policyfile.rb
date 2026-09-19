# frozen_string_literal: true

name 'aws-agents'
run_list 'test::default'
named_run_list :remove, 'test::remove'
cookbook 'aws', path: '.'
cookbook 'test', path: 'test/cookbooks/test'
