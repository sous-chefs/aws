#!/bin/sh
set -eu

: "${AWS_AGENT_PACKAGE_DIR:?Set AWS_AGENT_PACKAGE_DIR to an absolute temporary directory}"
case "$AWS_AGENT_PACKAGE_DIR" in
  /*) ;;
  *) echo 'AWS_AGENT_PACKAGE_DIR must be absolute' >&2; exit 1 ;;
esac

case "$(docker info --format '{{.Architecture}}')" in
  aarch64|arm64)
    arch=arm64
    cloudwatch_sha=f84cbb6b193f80440f713ec3a2b2b6ed45a16f10d8f0fe38c01cbff9155cb3f9
    ssm_sha=2ed75ecacf633af8b48568f1d468a4849ad006ff901f63761ecb9b0daa8d90d2
    ;;
  x86_64|amd64)
    arch=amd64
    cloudwatch_sha=05baeadca96c4bb8e43906ed09cf0bebd0f321ff6d41987bdc46ce681de0978d
    ssm_sha=777df4e0ac4bbc8d7d1b159db76cdb6614666bcc73141874414b8be68fb9cba3
    ;;
  *) echo 'Unsupported Docker architecture' >&2; exit 1 ;;
esac

mkdir -p "$AWS_AGENT_PACKAGE_DIR"
curl --fail --location --retry 3 \
  "https://amazoncloudwatch-agent.s3.amazonaws.com/ubuntu/$arch/1.300072.0b1766/amazon-cloudwatch-agent.deb" \
  --output "$AWS_AGENT_PACKAGE_DIR/amazon-cloudwatch-agent.deb"
printf '%s  %s\n' "$cloudwatch_sha" "$AWS_AGENT_PACKAGE_DIR/amazon-cloudwatch-agent.deb" | shasum -a 256 --check
curl --fail --location --retry 3 \
  "https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/3.3.5226.0/debian_$arch/amazon-ssm-agent.deb" \
  --output "$AWS_AGENT_PACKAGE_DIR/amazon-ssm-agent.deb"
printf '%s  %s\n' "$ssm_sha" "$AWS_AGENT_PACKAGE_DIR/amazon-ssm-agent.deb" | shasum -a 256 --check

docker pull dokken/ubuntu-24.04
docker pull cincproject/workstation:latest
docker build -t aws-agents-workstation:local test/docker
if docker network inspect aws-agents-offline >/dev/null 2>&1; then
  test "$(docker network inspect --format '{{.Internal}}' aws-agents-offline)" = true
else
  docker network create --internal --subnet 192.0.2.0/28 aws-agents-offline
fi
