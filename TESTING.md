# Testing

## Local Validation

Run the standard local validation stack with:

```shell
cookstyle
chef exec rspec --format documentation
KITCHEN_LOCAL_YAML=kitchen.dokken.yml kitchen test default-ubuntu-2404 --destroy=always
```

CI runs the `default` suite on every platform in `kitchen.dokken.yml`. The command above runs only Ubuntu 24.04 locally; omit the instance name to run the full matrix.

The `default` suite uses SDK stub responses and does not require live AWS credentials.

## Live AWS Validation

Live suites are defined in `kitchen.live.yml` and grouped by capability:

- `storage`
- `identity`
- `network`
- `compute`
- `orchestration`

Run them manually when the required AWS environment variables and EC2 SSH key path are available.

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
chef install Policyfile.agents.rb
kitchen test default-ubuntu-2404 --destroy=always
docker network rm aws-agents-offline
```

Kitchen enforces two converges with zero updates on the second. The preparation
script selects ARM64 or x86-64 packages to match Docker and verifies fixed SHA-256
checksums. These agent tests do not require the SDK gems declared for API resources;
the suite disables automatic installation of that separate pinned dependency set.
The default `kitchen.yml` runs API stubs. Use `kitchen.agents.yml` explicitly for host agents; live AWS suites remain in `kitchen.live.yml`.

For removal testing, retain the default instance with `kitchen converge` and
`kitchen verify`, then run the `remove` named run list twice inside the container.
The second removal must report zero updated resources. Check the package, cached
download and owned agent directory are absent before `kitchen destroy`.
