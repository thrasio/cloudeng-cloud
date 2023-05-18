# Common variables for all AWS accounts.
locals {
  # ----------------------------------------------------------------------------------------------------------------
  # ACCOUNT IDS AND CONVENIENCE LOCALS
  # ----------------------------------------------------------------------------------------------------------------

  # Centrally define all the AWS account IDs. We use JSON so that it can be readily parsed outside of Terraform.
  accounts = jsondecode(file("accounts.json"))

  # Define a default region to use when operating on resources that are not contained within a specific region.
  default_region = "us-east-1"

  # A prefix used for naming resources.
  name_prefix = "thrasio"

  # All accounts use the ECR repo in the shared account for the ecs-deploy-runner docker image.
  deploy_runner_ecr_uri             = "${local.accounts.shared}.dkr.ecr.${local.default_region}.amazonaws.com/ecs-deploy-runner"
  deploy_runner_container_image_tag = "v0.38.10.1"

  # All accounts use the ECR repo in the shared account for the Kaniko docker image.
  kaniko_ecr_uri             = "${local.accounts.shared}.dkr.ecr.${local.default_region}.amazonaws.com/kaniko"
  kaniko_container_image_tag = "v0.38.10"

  # The infastructure-live repository on which the deploy runner operates.
  infra_live_repo_https = "https://github.com/thrasio/cloud.git"
  infra_live_repo_ssh   = "git@github.com:thrasio/cloud.git"

  # These repos will be allowed for plan and apply operations in the CI/CD pipeline in addition to the value
  # provided in infra_live_repo_https
  additional_plan_and_apply_repos = [
    "git@github.com:gruntwork-clients/infrastructure-live-thrasio.git",
  ]

  # The name of the S3 bucket in the Logs account where AWS Config will report its findings.
  config_s3_bucket_name = "thrasio-config-logs"

  # The name of the S3 bucket in the Logs account where AWS CloudTrail will report its findings.
  cloudtrail_s3_bucket_name = "thrasio-cloudtrail-logs"

  # IAM configurations for cross account ssh-grunt setup.
  ssh_grunt_users_group      = "ssh-grunt-users"
  ssh_grunt_sudo_users_group = "ssh-grunt-sudo-users"
  allow_ssh_grunt_role       = "arn:aws:iam::${local.accounts.security}:role/allow-ssh-grunt-access-from-other-accounts"

  # -------------------------------------------------------------------------------------------------------------------
  # COMMON NETWORK CONFIGURATION DATA
  # -------------------------------------------------------------------------------------------------------------------

  # Map of account name to VPC CIDR blocks to use for the mgmt VPC.
  mgmt_vpc_cidrs = {
    cloud-eng-sandbox = "172.31.80.0/20"
    cloud-eng-services = "172.31.80.0/20"
    da-dev = "172.31.80.0/20"
    da-prod = "172.31.80.0/20"
    dabs-dev = "172.19.0.0/16"
    dabs-prod = "172.23.0.0/16"
    ds-dev = "172.20.0.0/16"
    ds-prod = "172.24.0.0/16"
    dw-dev = "172.31.80.0/20"
    dw-prod = "172.31.80.0/20"
    gatekeeper-dev = "172.31.80.0/20"
    gatekeeper-prod = "172.31.80.0/20"
    it-dev = "172.31.80.0/20"
    it-prod = "172.31.80.0/20"
    logs = "172.31.80.0/20"
    network = "172.31.80.0/20"
    security = "172.31.80.0/20"
    shared = "172.31.80.0/20"
    teleport = "172.31.80.0/20"
    joseph-oyomi-lab = "172.31.80.0/24"
    BenBrown-Lab = "172.31.80.0/24"
    mpmccann-lab = "172.31.80.0/24"
    financeeng-dev = "172.31.80.0/24"
    financeeng-prod = "172.31.80.0/24"
    affiliate-platform-dev = "172.31.80.0/24"
    affiliate-platform-prod = "172.31.80.0/24"
    cloudeng-dev = "172.31.80.0/24"
  }

  # Map of account name to VPC CIDR blocks to use for the app VPC.
  app_vpc_cidrs = {
    cloud-eng-sandbox = "10.30.0.0/16"
    cloud-eng-services = "10.72.0.0/16"
    da-dev = "10.26.0.0/16"
    da-prod = "10.76.0.0/16"
    dabs-dev = "10.14.0.0/16"
    dabs-prod = "10.62.0.0/16"
    ds-dev = "10.16.0.0/16"
    ds-prod = "10.64.0.0/16"
    dw-dev = "10.22.0.0/16"
    dw-prod = "10.70.0.0/16"
    gatekeeper-dev = "10.28.0.0/16"
    gatekeeper-prod = "10.78.0.0/16"
    it-dev = "10.32.0.0/16"
    it-prod = "10.80.0.0/16"
    shared = {
      dev = "10.9.0.0/16"
      prod = "10.115.0.0/16"
      }
    teleport = {
      dev = "10.7.0.0/16"
      prod = "10.113.0.0/16"
      }
    joseph-oyomi-lab = "10.38.0.0/16"
    BenBrown-Lab = "10.42.0.0/16"
    mpmccann-lab = "10.44.0.0/16"
    financeeng-dev = "10.46.0.0/16"
    financeeng-prod = "10.84.0.0/16"
    affiliate-platform-dev = "10.48.0.0/16"
    affiliate-platform-prod = "10.86.0.0/16"
    cloudeng-dev = "10.20.0.0/16"
  }

  # List of known static CIDR blocks for the organization. Administrative access (e.g., VPN, SSH,
  # etc) will be limited to these source CIDRs.
  ip_allow_list = [
    "0.0.0.0/0",
  ]

  # Information used to generate the CA certificate used by OpenVPN in each account
  ca_cert_fields = {
    ca_country  = "US"
    ca_email    = "cloud@thras.io"
    ca_locality = "Walpole"
    ca_org      = "Thrasio"
    ca_org_unit = "Engineering"
    ca_state    = "MA"
  }

  # Centrally define the internal services domain name configured by the route53-private module
  internal_services_domain_name = "thrasio.aws"
}
