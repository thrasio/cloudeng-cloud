include {
   path = find_in_parent_folders()
 }

 locals {
   # Automatically load common variables shared across all accounts
   common_vars = read_terragrunt_config(find_in_parent_folders("common.hcl"))

   # Extract the name prefix for easy access
   name_prefix = local.common_vars.locals.name_prefix

   # Automatically load account-level variables
   account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))

   # Extract the account_name for easy access
   account_name = local.account_vars.locals.account_name

   # Automatically load region-level variables
   region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))

   # Extract the region for easy access
   aws_region = local.region_vars.locals.aws_region

   datadog_secret_arn = "arn:aws:secretsmanager:us-east-1:491657507480:secret:dev/eks/datadog-QYcE2v"
 }

 inputs = {
   datadog_secret_arn = local.datadog_secret_arn
 }
 