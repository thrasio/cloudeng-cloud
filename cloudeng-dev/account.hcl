  locals {
    account_id   = "491657507480"
    account_name = "cloudeng-dev"
    account_infra_repo_ssh = "git@github.com:thrasio/cloudeng-cloud.git"
    sso_role_arn = "arn:aws:iam::491657507480:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_TC-Platform-Dev_3e7bc5ce191047b4"
    domain_name = {
      name            = "dev.cloudeng.thrasio.tools"
      hosted_zone_id  = "Z08716372MVU001F25H9K"
      certificate_arn = "arn:aws:acm:us-east-1:491657507480:certificate/f4ee11ca-8a5a-4cba-9638-91a0537763c6"
    }
  }