# ---------------------------------------------------------------------------------------------------------------------
# TERRAGRUNT CONFIGURATION
# This is the configuration for Terragrunt, a thin wrapper for Terraform that helps keep your code DRY and
# maintainable: https://github.com/gruntwork-io/terragrunt
# ---------------------------------------------------------------------------------------------------------------------
# Terragrunt will copy the Terraform configurations specified by the source parameter, along with any files in the
# working directory, into a temporary folder, and execute your Terraform commands in that folder. If you're iterating
# locally, you can use --terragrunt-source /path/to/local/checkout/of/module to override the source parameter to a
# local check out of the module for faster iteration.

locals {
  # Automatically load common variables shared across all accounts
  common_vars = read_terragrunt_config(find_in_parent_folders("common.hcl"))

  # Automatically load account-level variables
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))

  # Automatically load region-level variables
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))

  # Extract commonly used variables for easy acess
  name_prefix     = local.common_vars.locals.name_prefix
  account_name    = local.account_vars.locals.account_name
  account_id      = local.common_vars.locals.accounts[local.account_name]
  aws_region      = local.region_vars.locals.aws_region
  sso_role_arn    = local.account_vars.locals.sso_role_arn

  # Custom locals
  sealed_secrets = try(
    yamldecode(
      file("secrets.yaml"),
    ),
    {},
  )
}


terraform {
    source = "git::git@github.com:thrasio/cloud-modules.git//secrets/sealed-secrets?ref=v0.0.12"
}

# Include all settings from the root terragrunt.hcl file

include {
  path = find_in_parent_folders()
}

# ---------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETERS
# These are the variables we have to pass in to use the module specified in the terragrunt configuration above
# ---------------------------------------------------------------------------------------------------------------------

inputs = {
  sealed_secrets  = local.sealed_secrets.secrets
  sso_role_arn    = local.sso_role_arn
  account_id      = local.account_id
}