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
