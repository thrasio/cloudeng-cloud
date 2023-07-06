include {
  path = find_in_parent_folders()
}

dependency "vpc" {
  config_path = "${get_terragrunt_dir()}/../../../networking/vpc"

  mock_outputs = {
    vpc_id                 = "vpc-efgh5678"
    private_app_subnet_ids = ["subnet-abcd1234", "subnet-bcd1234a", ]
  }
  mock_outputs_allowed_terraform_commands = ["validate", ]
}

dependency "ecs_deploy_runner" {
  config_path = "${get_terragrunt_dir()}/../../../../mgmt/ecs-deploy-runner"

  mock_outputs = {
    ecs_task_iam_roles = {
      "terraform-applier" = {
        "arn" = "arn:aws:iam::12345679012:role/role-mock-2",
      "name" = "ecs-task-iam-role-mock-2", },
      "terraform-planner" = {
        "arn" = "arn:aws:iam::12345679012:role/role-mock-1",
      "name" = "ecs-task-iam-role-mock-1", },
    }

    security_group_allow_all_outbound_id = "sg-mockmockmockmock0"
  }
  mock_outputs_allowed_terraform_commands = ["validate", ]
}

terraform {
  source = "git::git@github.com:thrasio/cloud-modules.git//services/eks-cluster/cluster?ref=v0.1.7"
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

  # Name this cluster different than the default, as we already have a cluster with that name
  cluster_name = "cloudeng-dev"

  # Automatically load region-level variables
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))

  # Extract the region for easy access
  aws_region = local.region_vars.locals.aws_region

  # A local for more convenient access to the accounts map.
  accounts = local.common_vars.locals.accounts
}

inputs = {
  region                               = local.aws_region
  env                                  = local.cluster_name
  cluster_name                         = local.cluster_name
  public_subnets                       = []
  private_subnets                      = [dependency.vpc.outputs.private_app_subnet_ids[0], dependency.vpc.outputs.private_app_subnet_ids[1], dependency.vpc.outputs.private_app_subnet_ids[2]]
  vpc_id                               = dependency.vpc.outputs.vpc_id
  cluster_version                      = "1.26"
  cluster_endpoint_private_access      = true
  name                                 = "eks-${local.cluster_name}-cluster-worker-group"
  autoscaling_enabled                  = true
  cluster_enabled_log_types            = ["api","audit","authenticator","controllerManager","scheduler"]
  create                               = true


  aws_auth_roles = [
    {
      rolearn  = "arn:aws:iam::${local.accounts[local.account_name]}:role/allow-full-access-from-other-accounts"
      username = "sso-admin:{{SessionName}}"
      groups   = ["system:masters"]
    },
    {
      rolearn  = "arn:aws:iam::${local.accounts[local.account_name]}:role/ecs-deploy-runner-terraform-applier"
      username = "ecr-applier:{{SessionName}}"
      groups   = ["system:masters"]
    },
    {
      rolearn  = "arn:aws:iam::${local.accounts[local.account_name]}:role/ecs-deploy-runner-terraform-planner"
      username = "ecr-planner:{{SessionName}}"
      groups   = ["system:masters"]
    },

    # Permit the cross-account ecr runner module to plan/apply changes
    {
      rolearn  = dependency.ecs_deploy_runner.outputs.ecs_task_iam_roles["terraform-applier"]["arn"]
      username = "ecr-applier:{{SessionName}}"
      groups   = ["system:masters"]
    },
    {
      rolearn  = dependency.ecs_deploy_runner.outputs.ecs_task_iam_roles["terraform-planner"]["arn"]
      username = "ecr-planner:{{SessionName}}"
      groups   = ["system:masters"]
    },

    # Permit the AWS Root account access to the cluster
    {
      rolearn   = "arn:aws:iam::${local.accounts[local.account_name]}:role/OrganizationAccountAccessRole"
      username  = "root-account-access"
      groups    = ["system:masters"]
    },

    # Allow the Cloud-Eng SSO role cluster access
    {
      rolearn   = "arn:aws:iam::491657507480:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_TC-Platform-Dev_3e7bc5ce191047b4"
      username  = "sso-cloud-eng"
      groups    = ["system:masters"]
    },
    {
      rolearn   = "arn:aws:iam::491657507480:role/AWSReservedSSO_TC-Platform-Dev_3e7bc5ce191047b4"
      username  = "sso-cloud-eng"
      groups    = ["system:masters"]
    },
  ]

  aws_auth_users = []

  eks_worker_groups = {
    "wg1-standard": {
      "desired_size": "1",
      "max_size": "2",
      "min_size": "1",
      "capacity_type": "ON_DEMAND",
      "instance_types": ["r6a.xlarge"],
      "labels": {
        "Service": "standard"
      },
      "disk_size": "100"
      "taints": {
/*        "dedicated": {
          "key": "Example"
          "value": "Value"
          "effect": "NO_SCHEDULE"
        }*/
      },
      "create_security_group": true,
      "security_group_name": "wg1-standard-node-group-sg",
      "security_group_use_name_prefix": false,
      "security_group_description": "EKS managed node group security group"
      "security_group_rules": {
        "istioGRPC": {
          "description": "Istio XDS and CA services"
          "protocol": "tcp"
          "from_port": 15012
          "to_port": 15012
          "type": "ingress"
          "self": true
        },
        "argocdRedis": {
          "description": "Argocd haproxy redis connection"
          "protocol": "tcp"
          "from_port": 6379
          "to_port": 6379
          "type": "ingress"
          "self": true
        },
        "argocdRedis2": {
          "description": "Argocd haproxy redis connection"
          "protocol": "tcp"
          "from_port": 26379
          "to_port": 26379
          "type": "ingress"
          "self": true
        },
        "argocdRepoServer": {
          "description": "Argocd Repo Server connection"
          "protocol": "tcp"
          "from_port": 8081
          "to_port": 8081
          "type": "ingress"
          "self": true
        },
        "IstioHTTPIngress": {
          "description": "Istio HTTP Ingress"
          "protocol": "tcp"
          "from_port": 80
          "to_port": 80
          "type": "ingress"
          "self": true
        },
        "IstioHTTPSIngress": {
          "description": "Istio HTTPS Ingress"
          "protocol": "tcp"
          "from_port": 443
          "to_port": 443
          "type": "ingress"
          "self": true
        },
        "IstioWebhook": {
          "description": "Istio Webhook Container Port"
          "protocol": "tcp"
          "from_port": 15017
          "to_port": 15017
          "type": "ingress"
          "source_cluster_security_group": true
        },
        "ALBControllerWebhook": {
          "description": "ALB Controller Cluster API to node 9443/tcp webhook"
          "protocol": "tcp"
          "from_port": 9443
          "to_port": 9443
          "type": "ingress"
          "source_cluster_security_group": true
        },
        "MetricsServerWebhook": {
          "description": "Metrics Server Cluster API to node 4443/tcp webhook"
          "protocol": "tcp"
          "from_port": 4443
          "to_port": 4443
          "type": "ingress"
          "source_cluster_security_group": true
        },
        "ArgoCDDex": {
          "description": "ArgoCD Dex port 5556/tcp for Okta SSO"
          "protocol": "tcp"
          "from_port": 5556
          "to_port": 5556
          "type": "ingress"
          "self": true
        },
        "Outbound": {
          "description": "Full outbound access from node group"
          "protocol": "all"
          "from_port": 0
          "to_port": 0
          "type": "egress"
          "cidr_blocks": ["0.0.0.0/0"]
        }
      }
    },
  }

  eks_tags = {
    "Environment"                                                         = local.cluster_name,
    "Name"                                                                = local.cluster_name,
  }

  eks_worker_tags = {
    "k8s.io/cluster-autoscaler/enabled"                                   = 1,
    "k8s.io/cluster-autoscaler/${local.cluster_name}"                     = 1,
  }
}

