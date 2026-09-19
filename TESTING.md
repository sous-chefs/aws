# Testing

Please refer to [the community cookbook documentation on testing](https://github.com/chef-cookbooks/community_cookbook_documentation/blob/main/TESTING.MD).

## Host agents

Unit tests use local cookbooks and no AWS credentials:

```sh
chef exec rspec
cookstyle libraries/agent_packages.rb resources/cloudwatch_agent.rb spec/resources/cloudwatch_agent_spec.rb spec/unit/agent_packages_spec.rb
```

CI also runs `bundle exec rspec` and `bundle exec cookstyle` on Ruby 3.2. Install
the test dependencies with `bundle install`; the Gemfile selects a compatible Chef
runtime independently of the legacy runtime SDK constraints in `metadata.rb`.

The agent Kitchen suite installs real pinned AWS packages on Ubuntu 24.04 with
systemd, translates configuration and verifies service state. Downloads happen
before an internal Docker network isolates the runner. Dummy CloudWatch credentials
meet the local translator's profile requirement; they cannot access AWS.
The host requires Docker, Cinc Workstation, curl and shasum. Run from the cookbook:

```sh
export AWS_AGENT_PACKAGE_DIR="$(mktemp -d)"
sh test/prepare-agents.sh
export KITCHEN_YAML=kitchen.agents.yml
export KITCHEN_LOCAL_YAML=kitchen.agents.yml
chef install Policyfile.rb
kitchen test default-ubuntu-2404 --destroy=always
docker network rm aws-agents-offline
```

Kitchen enforces two converges with zero updates on the second. The preparation
script selects ARM64 or x86-64 packages to match Docker and verifies fixed SHA-256
checksums. These agent tests do not require the SDK gems declared for API resources;
the suite disables automatic installation of that separate pinned dependency set.
The legacy `kitchen.yml` uses real EC2 instances; use `kitchen.agents.yml` explicitly.

For removal testing, retain the default instance with `kitchen converge` and
`kitchen verify`, then run the `remove` named run list twice inside the container.
The second removal must report zero updated resources. Check the package, cached
download and owned agent directory are absent before `kitchen destroy`.
