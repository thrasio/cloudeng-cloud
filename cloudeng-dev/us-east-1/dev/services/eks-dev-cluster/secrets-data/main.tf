data "aws_secretsmanager_secret" "dd" {
  arn = var.datadog_secret_arn
}

data "aws_secretsmanager_secret_version" "dd" {
  secret_id = data.aws_secretsmanager_secret.dd.id
}

locals {
  dd_secrets = jsondecode(
    data.aws_secretsmanager_secret_version.dd.secret_string
  )
}
