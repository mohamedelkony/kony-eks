locals {
  remote_node_cidr = var.remote_network_cidr
  remote_pod_cidr  = var.remote_pod_cidr

  eks_managed_node_groups = {
    controllers = {
      instance_types           = ["t3.small"]
      force_update_version     = true
      release_version          = var.ami_release_version
      use_name_prefix          = false
      iam_role_name            = "${var.cluster_name}-ng-controllers"
      iam_role_use_name_prefix = false

      min_size     = 0
      max_size     = 4
      desired_size = 1

      update_config = {
        max_unavailable_percentage = 50
      }

      labels = {
        workload-group = "controllers"
        workload-tier  = "platform"
        workshop-size  = "small"
      }
    }

    backend-apis = {
      instance_types           = ["t3.small"]
      force_update_version     = true
      release_version          = var.ami_release_version
      use_name_prefix          = false
      iam_role_name            = "${var.cluster_name}-ng-backend-apis"
      iam_role_use_name_prefix = false

      min_size     = 0
      max_size     = 4
      desired_size = 1

      update_config = {
        max_unavailable_percentage = 50
      }

      labels = {
        workload-group = "backend-apis"
        workload-tier  = "application"
        workshop-size  = "small"
      }
    }

    stateless-noncritical = {
      instance_types           = ["t3.small"]
      force_update_version     = true
      release_version          = var.ami_release_version
      use_name_prefix          = false
      iam_role_name            = "${var.cluster_name}-ng-stateless-noncritical"
      iam_role_use_name_prefix = false

      min_size     = 0
      max_size     = 4
      desired_size = 1

      update_config = {
        max_unavailable_percentage = 50
      }

      labels = {
        workload-group = "stateless-noncritical"
        workload-tier  = "application"
        workshop-size  = "small"
      }
    }
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name                             = var.cluster_name
  cluster_version                          = var.cluster_version
  cluster_endpoint_public_access           = true
  enable_cluster_creator_admin_permissions = true

  cluster_addons = {
    vpc-cni = {
      before_compute = true
      most_recent    = true
      configuration_values = jsonencode({
        env = {
          ENABLE_POD_ENI                    = "true"
          ENABLE_PREFIX_DELEGATION          = "true"
          POD_SECURITY_GROUP_ENFORCING_MODE = "standard"
        }
        nodeAgent = {
          enablePolicyEventLogs = "true"
        }
        enableNetworkPolicy = "true"
      })
    }
  }

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  create_cluster_security_group = false
  create_node_security_group    = false
  cluster_security_group_additional_rules = {
    hybrid-node = {
      cidr_blocks = [local.remote_node_cidr]
      description = "Allow all traffic from remote node/pod network"
      from_port   = 0
      to_port     = 0
      protocol    = "all"
      type        = "ingress"
    }

    hybrid-pod = {
      cidr_blocks = [local.remote_pod_cidr]
      description = "Allow all traffic from remote node/pod network"
      from_port   = 0
      to_port     = 0
      protocol    = "all"
      type        = "ingress"
    }
  }

  node_security_group_additional_rules = {
    hybrid_node_rule = {
      cidr_blocks = [local.remote_node_cidr]
      description = "Allow all traffic from remote node/pod network"
      from_port   = 0
      to_port     = 0
      protocol    = "all"
      type        = "ingress"
    }

    hybrid_pod_rule = {
      cidr_blocks = [local.remote_pod_cidr]
      description = "Allow all traffic from remote node/pod network"
      from_port   = 0
      to_port     = 0
      protocol    = "all"
      type        = "ingress"
    }
  }


  cluster_remote_network_config = {
    remote_node_networks = {
      cidrs = [local.remote_node_cidr]
    }
    # Required if running webhooks on Hybrid nodes
    remote_pod_networks = {
      cidrs = [local.remote_pod_cidr]
    }
  }

  eks_managed_node_groups = local.eks_managed_node_groups

  tags = merge(local.tags, {
    "karpenter.sh/discovery" = var.cluster_name
  })
}
