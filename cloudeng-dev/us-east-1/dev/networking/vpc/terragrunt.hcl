# ---------------------------------------------------------------------------------------------------------------------
# TERRAGRUNT CONFIGURATION
# This is the configuration for Terragrunt, a thin wrapper for Terraform that helps keep your code DRY and
# maintainable: https://github.com/gruntwork-io/terragrunt
# ---------------------------------------------------------------------------------------------------------------------

# Terragrunt will copy the Terraform configurations specified by the source parameter, along with any files in the
# working directory, into a temporary folder, and execute your Terraform commands in that folder. If you're iterating
# locally, you can use --terragrunt-source /path/to/local/checkout/of/module to override the source parameter to a
# local check out of the module for faster iteration.
terraform {
  source = "git::git@github.com:gruntwork-io/terraform-aws-service-catalog.git//modules/networking/vpc?ref=v0.104.2"
}

# Include all settings from the root terragrunt.hcl file
include {
  path = find_in_parent_folders()
}


dependency "vpc_mgmt" {
  config_path                             = "${get_terragrunt_dir()}/../../../mgmt/vpc-mgmt"
  mock_outputs                            = {
    vpc_id                                = "vpc-abcd1234"
    private_persistence_subnet_ids        = ["subnet-abcd1234", "subnet-bcd1234a", ]
    private_app_subnet_cidr_blocks        = ["10.0.0.0/24", "10.0.1.0/24", ]
  }
  mock_outputs_allowed_terraform_commands = ["validate", ]
}

# ---------------------------------------------------------------------------------------------------------------------
# Locals are named constants that are reusable within the configuration.
# ---------------------------------------------------------------------------------------------------------------------
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

}

# ---------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETERS
# These are the variables we have to pass in to use the module specified in the terragrunt configuration above
# ---------------------------------------------------------------------------------------------------------------------
inputs = {
  vpc_name                                  = "dev"
  num_nat_gateways                          = 3
  cidr_block                                = local.common_vars.locals.app_vpc_cidrs[local.account_name]
  kms_key_user_iam_arns                     = [
    "arn:aws:iam::${local.common_vars.locals.accounts[local.account_name]}:root",
  ]
  eks_cluster_names                         = [local.account_name]
  tag_for_use_with_eks                      = true
  allow_private_persistence_internet_access = true
  create_peering_connection                 = true
  origin_vpc_id                             = dependency.vpc_mgmt.outputs.vpc_id
  origin_vpc_name                           = dependency.vpc_mgmt.outputs.vpc_name
  origin_vpc_route_table_ids                = dependency.vpc_mgmt.outputs.private_subnet_route_table_ids
  origin_vpc_cidr_block                     = dependency.vpc_mgmt.outputs.vpc_cidr_block
  origin_vpc_public_subnet_ids              = dependency.vpc_mgmt.outputs.public_subnet_ids
  create_dns_forwarder                      = false
}