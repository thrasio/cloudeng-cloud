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
 EOF
}

terraform {
   source = "git::git@github.com:thrasio/cloud-modules.git//services/eks-cluster/helm/argocd?ref=v0.1.7"
}

dependency "cluster" {
   config_path = "../../cluster"
}

locals {
   # Automatically load common variables shared across all accounts
   common_vars = read_terragrunt_config(find_in_parent_folders("common.hcl"))

   # Automatically load account-level variables
   account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))

   # ArgoCD helm version
   argo_helm_version = "5.38.0"

   # ArgoCD Cluster Variables
   cluster_domain           = local.account_vars.locals.domain_name.name
   certificate_arn          = local.account_vars.locals.domain_name.certificate_arn
   okta_sso_url             = "https://thrasio.okta.com/app/thrasio_ssoargocdcloudengdevargocddevcloudengthrasiotools_1/exkts4faegB95UkLQ357/sso/saml"
   okta_secret_arn          = "arn:aws:secretsmanager:us-east-1:491657507480:secret:argocd-YUtLUM"

   rbac_config_policy_csv   = [
     "g, TC-Platform, role:admin",
     "g, Everyone, role:readonly",
     "p, role:splat-ci-service-role, applications, get, */*, allow",
     "p, role:splat-ci-service-role, applications, sync, */*, allow",
     "p, role:splat-ci-service-role, applications, update, */*, allow",
     "p, role:splat-ci-service-role, projects, get, *, allow"
    ]
}
# Passed to main.tf
inputs = {
  okta_sso_url              = local.okta_sso_url
  okta_secret_arn           = local.okta_secret_arn
  rbac_config_policy_csv    = local.rbac_config_policy_csv
  ingress_url               = "argocd.${local.cluster_domain}"
  ingress_certificate_arn   = local.certificate_arn
  argocd_helm_chart_version = local.argo_helm_version
}