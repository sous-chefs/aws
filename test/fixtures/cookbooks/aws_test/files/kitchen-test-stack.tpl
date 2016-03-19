{
  "AWSTemplateFormatVersion": "2010-09-09",
  "Description": "kitchen-test-stack",
  "Resources": {
    "DummyResource": {
       "Type" : "AWS::CloudFormation::WaitConditionHandle",
       "Properties" : {
       }
    }
  }
}
