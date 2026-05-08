locals {
  cluster_autoscaler_asg_tags = {
    "k8s.io/cluster-autoscaler/enabled"             = "true"
    "k8s.io/cluster-autoscaler/${var.cluster_name}" = "owned"
  }

  cluster_autoscaler_managed_node_group_asg_tags = merge([
    for node_group_name, node_group in module.eks.eks_managed_node_groups : merge([
      for asg_name in node_group.node_group_autoscaling_group_names : {
        for tag_key, tag_value in local.cluster_autoscaler_asg_tags :
        "${node_group_name}/${asg_name}/${tag_key}" => {
          autoscaling_group_name = asg_name
          key                    = tag_key
          value                  = tag_value
        }
      }
    ]...)
  ]...)
}

data "aws_iam_policy_document" "cluster_autoscaler_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      variable = "${module.eks.oidc_provider}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${module.eks.oidc_provider}:sub"
      values = [
        "system:serviceaccount:${var.cluster_autoscaler_namespace}:${var.cluster_autoscaler_service_account_name}"
      ]
    }

    principals {
      type        = "Federated"
      identifiers = [module.eks.oidc_provider_arn]
    }
  }
}

data "aws_iam_policy_document" "cluster_autoscaler" {
  statement {
    sid = "ScaleDiscoveredNodeGroups"

    actions = [
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/k8s.io/cluster-autoscaler/enabled"
      values   = ["true"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/k8s.io/cluster-autoscaler/${var.cluster_name}"
      values   = ["owned"]
    }
  }

  statement {
    sid = "DescribeNodeGroups"

    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeScalingActivities",
      "autoscaling:DescribeTags",
      "ec2:DescribeImages",
      "ec2:DescribeInstanceTypes",
      "ec2:DescribeLaunchTemplateVersions",
      "ec2:GetInstanceTypesFromInstanceRequirements",
      "eks:DescribeNodegroup",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "cluster_autoscaler" {
  name        = "${var.cluster_name}-ClusterAutoscalerIAMPolicy"
  description = "IAM policy for Cluster Autoscaler"
  policy      = data.aws_iam_policy_document.cluster_autoscaler.json
}

resource "aws_iam_role" "cluster_autoscaler" {
  name               = "${var.cluster_name}-cluster-autoscaler"
  assume_role_policy = data.aws_iam_policy_document.cluster_autoscaler_assume_role.json
}

resource "aws_iam_role_policy_attachment" "cluster_autoscaler" {
  role       = aws_iam_role.cluster_autoscaler.name
  policy_arn = aws_iam_policy.cluster_autoscaler.arn
}

resource "aws_autoscaling_group_tag" "cluster_autoscaler" {
  for_each = local.cluster_autoscaler_managed_node_group_asg_tags

  autoscaling_group_name = each.value.autoscaling_group_name

  tag {
    key                 = each.value.key
    value               = each.value.value
    propagate_at_launch = false
  }
}

resource "kubernetes_service_account_v1" "cluster_autoscaler" {
  metadata {
    name      = var.cluster_autoscaler_service_account_name
    namespace = var.cluster_autoscaler_namespace
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.cluster_autoscaler.arn
    }
    labels = {
      "app.kubernetes.io/name"      = "cluster-autoscaler"
      "app.kubernetes.io/component" = "controller"
    }
  }

  depends_on = [module.eks]
}

resource "helm_release" "cluster_autoscaler" {
  name       = "cluster-autoscaler"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  version    = var.cluster_autoscaler_chart_version
  namespace  = var.cluster_autoscaler_namespace

  values = [yamlencode({
    cloudProvider = "aws"
    awsRegion     = data.aws_region.current.name
    autoDiscovery = {
      clusterName = module.eks.cluster_name
    }
    image = {
      tag = var.cluster_autoscaler_image_tag
    }
    rbac = {
      serviceAccount = {
        create = false
        name   = var.cluster_autoscaler_service_account_name
      }
    }
  })]

  depends_on = [
    module.eks,
    kubernetes_service_account_v1.cluster_autoscaler,
    aws_iam_role_policy_attachment.cluster_autoscaler,
    aws_autoscaling_group_tag.cluster_autoscaler,
  ]
}
