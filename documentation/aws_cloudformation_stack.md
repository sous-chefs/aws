# aws_cloudformation_stack

## Summary

Create, update, and delete CloudFormation stacks from cookbook-managed templates.

## Shared Properties

All resources support `region`, `aws_access_key`, `aws_secret_access_key`, `aws_session_token`, `aws_assume_role_arn`, and `aws_role_session_name` through the shared AWS partial.

## Actions

- `:create`
- `:delete`

## Notes

Use the resource name shown in this document as the public DSL entrypoint. For property details and examples, see the main README and the corresponding resource implementation in `resources/`.
