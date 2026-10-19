# frozen_string_literal: true

require 'spec_helper'
require 'uri'

describe 'IAM policy document decoding' do
  platform 'ubuntu', '24.04'
  let(:document) { '{"Version":"2012-10-17","Statement":[],"Id":"literal+plus"}' }
  let(:encoded) { document.gsub('{', '%7B').gsub('}', '%7D').gsub('"', '%22') }

  recipe do
    aws_iam_policy 'example' do
      policy_document '{"Version":"2012-10-17","Statement":[],"Id":"literal+plus"}'
      action :nothing
    end
    aws_iam_role 'example' do
      assume_role_policy_document '{"Version":"2012-10-17","Statement":[],"Id":"literal+plus"}'
      action :nothing
    end
  end

  it 'decodes managed policy escapes without turning literal plus signs into spaces' do
    provider = chef_run.aws_iam_policy('example').provider_for_action(:create)
    client = double('IAM')
    allow(provider).to receive(:iam).and_return(client)
    allow(provider).to receive(:make_policy_arn).and_return('arn:aws:iam::123456789012:policy/example')
    allow(client).to receive(:get_policy).and_return(double(policy: double(default_version_id: 'v1')))
    allow(client).to receive(:get_policy_version).and_return(double(policy_version: double(document: encoded)))
    expect(provider.policy_changed?).to be false
  end

  it 'decodes assume-role policy escapes without changing literal plus signs' do
    provider = chef_run.aws_iam_role('example').provider_for_action(:create)
    client = double('IAM')
    allow(provider).to receive(:iam).and_return(client)
    allow(client).to receive(:get_role).and_return(double(role: double(assume_role_policy_document: encoded)))
    expect(provider.assume_role_policy_changed?).to be false
  end
end
