# this document is a copy of the AWS ReadOnly managed policy v3
aws_iam_policy 'test-kitchen-policy' do
  action :create
  policy_document <<-EOH.gsub(/^ {4}/, '')
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Action": [
            "appstream:Get*",
            "autoscaling:Describe*",
            "cloudformation:DescribeStackEvents",
            "cloudformation:DescribeStackResource",
            "cloudformation:DescribeStackResources",
            "cloudformation:DescribeStacks",
            "cloudformation:GetTemplate",
            "cloudformation:List*",
            "cloudfront:Get*",
            "cloudfront:List*",
            "cloudsearch:Describe*",
            "cloudsearch:List*",
            "cloudtrail:DescribeTrails",
            "cloudtrail:GetTrailStatus",
            "cloudwatch:Describe*",
            "cloudwatch:Get*",
            "cloudwatch:List*",
            "codedeploy:Batch*",
            "codedeploy:Get*",
            "codedeploy:List*",
            "config:Deliver*",
            "config:Describe*",
            "config:Get*",
            "datapipeline:DescribeObjects",
            "datapipeline:DescribePipelines",
            "datapipeline:EvaluateExpression",
            "datapipeline:GetPipelineDefinition",
            "datapipeline:ListPipelines",
            "datapipeline:QueryObjects",
            "datapipeline:ValidatePipelineDefinition",
            "directconnect:Describe*",
            "dynamodb:BatchGetItem",
            "dynamodb:DescribeTable",
            "dynamodb:GetItem",
            "dynamodb:ListTables",
            "dynamodb:Query",
            "dynamodb:Scan",
            "ec2:Describe*",
            "ec2:GetConsoleOutput",
            "ecs:Describe*",
            "ecs:List*",
            "elasticache:Describe*",
            "elasticbeanstalk:Check*",
            "elasticbeanstalk:Describe*",
            "elasticbeanstalk:List*",
            "elasticbeanstalk:RequestEnvironmentInfo",
            "elasticbeanstalk:RetrieveEnvironmentInfo",
            "elasticloadbalancing:Describe*",
            "elasticmapreduce:Describe*",
            "elasticmapreduce:List*",
            "elastictranscoder:List*",
            "elastictranscoder:Read*",
            "iam:GenerateCredentialReport",
            "iam:Get*",
            "iam:List*",
            "kinesis:Describe*",
            "kinesis:Get*",
            "kinesis:List*",
            "kms:Describe*",
            "kms:Get*",
            "kms:List*",
            "logs:Describe*",
            "logs:Get*",
            "logs:TestMetricFilter",
            "opsworks:Describe*",
            "opsworks:Get*",
            "rds:Describe*",
            "rds:ListTagsForResource",
            "redshift:Describe*",
            "redshift:ViewQueriesInConsole",
            "route53:Get*",
            "route53:List*",
            "route53domains:CheckDomainAvailability",
            "route53domains:GetDomainDetail",
            "route53domains:GetOperationDetail",
            "route53domains:ListDomains",
            "route53domains:ListOperations",
            "route53domains:ListTagsForDomain",
            "s3:Get*",
            "s3:List*",
            "sdb:GetAttributes",
            "sdb:List*",
            "sdb:Select*",
            "ses:Get*",
            "ses:List*",
            "sns:Get*",
            "sns:List*",
            "sqs:GetQueueAttributes",
            "sqs:ListQueues",
            "sqs:ReceiveMessage",
            "storagegateway:Describe*",
            "storagegateway:List*",
            "swf:Count*",
            "swf:Describe*",
            "swf:Get*",
            "swf:List*",
            "tag:Get*",
            "trustedadvisor:Describe*"
          ],
          "Effect": "Allow",
          "Resource": "*"
        }
      ]
    }
  EOH
  aws_access_key node['aws_test']['key_id']
  aws_secret_access_key node['aws_test']['access_key']
  aws_session_token node['aws_test']['session_token']
end

aws_iam_policy 'test-kitchen-policy' do
  aws_access_key node['aws_test']['key_id']
  aws_secret_access_key node['aws_test']['access_key']
  aws_session_token node['aws_test']['session_token']
  action :delete
end
