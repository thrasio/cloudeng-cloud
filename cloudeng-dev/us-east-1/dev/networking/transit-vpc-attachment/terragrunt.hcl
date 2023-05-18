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
  source = "git@github.com:thrasio/cloud-modules.git//transit-vpc-attachment"
}

# Include all settings from the root terragrunt.hcl file
include {
  path = find_in_parent_folders()
}

dependency "vpc" {
  config_path = "${get_terragrunt_dir()}/../vpc"

  mock_outputs = {
    vpc_name                       = "prod"
    vpc_id                         = "vpc-abcd1234"
    private_persistence_subnet_ids = ["subnet-abcd1234", "subnet-bcd1234a", ]
    private_app_subnet_cidr_blocks = ["10.0.0.0/24", "10.0.1.0/24", ]
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

  # A local for more convenient access to the accounts map.
  accounts = local.common_vars.locals.accounts

  # Automatically load network-level variables
  network_vars = read_terragrunt_config(find_in_parent_folders("network.hcl"))
}

# ---------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETERS
# These are the variables we have to pass in to use the module specified in the terragrunt configuration above
# ---------------------------------------------------------------------------------------------------------------------
inputs = {
  vpc_id     = dependency.vpc.outputs.vpc_id
  vpc_name   = dependency.vpc.outputs.vpc_name
  private_app_subnet_ids = dependency.vpc.outputs.private_app_subnet_ids # List of subnets, one per AZ
  transit_owner_account = local.accounts.shared
  private_app_subnet_route_table_ids = dependency.vpc.outputs.private_app_subnet_route_table_ids
  private_persistence_route_table_ids = dependency.vpc.outputs.private_persistence_route_table_ids
  public_subnet_route_table_id = dependency.vpc.outputs.public_subnet_route_table_id
  create_private_persistence_route = false
  private_app_subnets_network_acl_id = dependency.vpc.outputs.private_app_subnets_network_acl_id
  private_persistence_subnets_network_acl_id = dependency.vpc.outputs.private_persistence_subnets_network_acl_id
  vpn_cidr = local.network_vars.locals.dev_perimeter_cidr
  vpn_ports_to_allow = ["22","443","80"]
}