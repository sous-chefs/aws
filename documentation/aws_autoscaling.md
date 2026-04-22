# aws_autoscaling

## Summary

Manage Auto Scaling instance lifecycle actions.

## Shared Properties

All resources support `region`, `aws_access_key`, `aws_secret_access_key`, `aws_session_token`, `aws_assume_role_arn`, and `aws_role_session_name` through the shared AWS partial.

## Actions

- `:enter_standby`
- `:exit_standby`
- `:attach_instance`
- `:detach_instance`
- `:create_asg`
- `:delete_asg`
- `:create_launch_config`
- `:delete_launch_config`

## Notes

Use the resource name shown in this document as the public DSL entrypoint. For property details and examples, see the main README and the corresponding resource implementation in `resources/`.
