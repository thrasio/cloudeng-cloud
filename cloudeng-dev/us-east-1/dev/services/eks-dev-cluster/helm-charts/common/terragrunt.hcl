include {
   path = find_in_parent_folders()
 }

generate "helm" {
   path      = "helm.tf"
   if_exists = "overwrite_terragrunt"
   contents  = <<EOF
 terraform {
   required_providers {
     helm = {
       version = "~> 2.2"
     }
     kubernetes = {
       version = "~> 2.3"
     }
     kubectl = {
       source = "gavinbunney/kubectl"
       version = ">= 1.7.0"
     }
   }
 }
 data "aws_eks_cluster" "cluster" {
   name = "${dependency.cluster.outputs.cluster_id}"
 }
 data "aws_eks_cluster_auth" "kubernetes_token" {
   name = "${dependency.cluster.outputs.cluster_id}"
 }
 provider "kubernetes" {
   load_config_file       = false
   host                   = data.aws_eks_cluster.cluster.endpoint
   cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
   token                  = data.aws_eks_cluster_auth.kubernetes_token.token
 }
 provider "helm" {
   kubernetes {
     host                   = data.aws_eks_cluster.cluster.endpoint
     cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
     token                  = data.aws_eks_cluster_auth.kubernetes_token.token
   }
 }
 provider "kubectl" {
   load_config_file       = false
   host                   = data.aws_eks_cluster.cluster.endpoint
   cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
   token                  = data.aws_eks_cluster_auth.kubernetes_token.token
 }
 EOF
}

terraform {
  source = "git::git@github.com:thrasio/cloud-modules.git//services/eks-cluster/helm/eks-core?ref=v0.1.19"
}

dependency "vpc" {
  config_path = "${get_terragrunt_dir()}/../../../../networking/vpc"

  mock_outputs = {
    vpc_id                 = "vpc-efgh5678"
    private_app_subnet_ids = ["subnet-abcd1234", "subnet-bcd1234a", ]
  }
  mock_outputs_allowed_terraform_commands = ["validate", ]
}

dependency "cluster" {
   config_path = "../../cluster"

   mock_outputs = {
     cluster_oidc_issuer_url = "https://oidc.eks.us-east-1.amazonaws.com/id/AAAAAAAAAAAAAAAAAAAAAAH"
   }
   mock_outputs_allowed_terraform_commands = ["validate", ]
}

dependency "secrets" {
   config_path = "../../secrets-data"
   mock_outputs = {
     datadog_app_key = "asdfghjkl12345"
     datadog_api_key = "asdfghjkl12345"
   }
   mock_outputs_allowed_terraform_commands = ["validate", ]
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

   # A local for more convenient access to the accounts map.
   accounts = local.common_vars.locals.accounts

   # Automatically load region-level variables
   region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))

   # Extract the region for easy access
   aws_region = local.region_vars.locals.aws_region

   # External DNS domain info 
   cluster_domain = local.account_vars.locals.domain_name.name
   cluster_hosted_zone_id = local.account_vars.locals.domain_name.hosted_zone_id
   # External Secrets Operator Resource ARNs
   external_secret_resource_arns = [ "arn:aws:secretsmanager:us-east-1:491657507480:secret:dev/*" ]

   #TODO define txt record for the cluster domain
   cluster_domain_txt_record_id = "external-dns-dev"

   # Helm chart versions
   alb_controller_helm_chart_version = "1.4.8"
   cert_manager_helm_chart_version = "1.11.0"
   cluster_autoscaler_helm_chart_version = "9.25.0"
   cluster_autoscaler_image_version_tag = "v1.24.0"
   external_dns_helm_chart_version = "6.14.0"
   datadog_helm_chart_version = "3.11.0"
   metrics_server_helm_chart_version = "3.8.3"
   external_secrets_operator_helm_chart_version ="0.7.2"
   istio_helm_chart_version = "1.17.1"
}

# Passed to thrasio/cloud-modules/eks/helm-charts
 inputs = {
   account_id                      = local.common_vars.locals.accounts[local.account_name]
   vpc_id                          = dependency.vpc.outputs.vpc_id
   aws_region                      = local.aws_region
   kubernetes_cluster_name         = dependency.cluster.outputs.cluster_id
   cluster_oidc_issuer_url         = dependency.cluster.outputs.cluster_oidc_issuer_url
   cluster_domain_txt_record_id    = local.cluster_domain_txt_record_id
   cluster_domain                  = local.cluster_domain
   datadog_api_key                 = dependency.secrets.outputs.datadog_api_key
   datadog_app_key                 = dependency.secrets.outputs.datadog_app_key

   external_dns_helm_chart_version        = local.external_dns_helm_chart_version
   alb_controller_helm_chart_version      = local.alb_controller_helm_chart_version
   cert_manager_helm_chart_version        = local.cert_manager_helm_chart_version
   cluster_autoscaler_helm_chart_version  = local.cluster_autoscaler_helm_chart_version
   cluster_autoscaler_image_version_tag   = local.cluster_autoscaler_image_version_tag
   datadog_helm_chart_version             = local.datadog_helm_chart_version
   metrics_server_helm_chart_version      = local.metrics_server_helm_chart_version
   istio_helm_chart_version               = local.istio_helm_chart_version

   cert_manager_enabled                   = true
   cert_manager_hosted_zone_id            = local.cluster_hosted_zone_id

   external_secrets_operator_enabled      = true
   external_secrets_operator_resource_arns= local.external_secret_resource_arns

   teleport_kube_agent_enabled     = true
   teleport_configured_apps        = []
}