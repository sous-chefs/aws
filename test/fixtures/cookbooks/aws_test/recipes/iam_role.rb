aws_iam_role 'test-kitchen-role' do
  action :create
  assume_role_policy_document <<-EOH.gsub(/^ {4}/, '')
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Sid": "",
          "Effect": "Deny",
          "Principal": {
            "AWS": "*"
          },
          "Action": "sts:AssumeRole"
        }
      ]
    }
  EOH
end
