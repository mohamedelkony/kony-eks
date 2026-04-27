locals {
  external_dns_hosted_zone_arns = [
    for zone_id in var.external_dns_hosted_zone_ids : "arn:aws:route53:::hostedzone/${zone_id}"
  ]
}

data "aws_iam_policy_document" "external_dns_assume_role" {
  count = var.external_dns_enabled ? 1 : 0

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
        "system:serviceaccount:${var.external_dns_namespace}:${var.external_dns_service_account_name}"
      ]
    }

    principals {
      type        = "Federated"
      identifiers = [module.eks.oidc_provider_arn]
    }
  }
}

data "aws_iam_policy_document" "external_dns" {
  count = var.external_dns_enabled ? 1 : 0

  statement {
    sid = "ChangeRecordsInManagedZones"

    actions = [
      "route53:ChangeResourceRecordSets",
    ]

    resources = local.external_dns_hosted_zone_arns
  }

  statement {
    sid = "ReadManagedZones"

    actions = [
      "route53:ListResourceRecordSets",
      "route53:ListTagsForResource",
    ]

    resources = local.external_dns_hosted_zone_arns
  }

  statement {
    sid = "ListHostedZones"

    actions = [
      "route53:ListHostedZones",
    ]

    resources = ["*"]
  }

  statement {
    sid = "GetRoute53ChangeStatus"

    actions = [
      "route53:GetChange",
    ]

    resources = ["arn:aws:route53:::change/*"]
  }
}

resource "aws_iam_policy" "external_dns" {
  count = var.external_dns_enabled ? 1 : 0

  name        = "${var.cluster_name}-ExternalDNSIAMPolicy"
  description = "IAM policy for ExternalDNS"
  policy      = data.aws_iam_policy_document.external_dns[0].json
}

resource "aws_iam_role" "external_dns" {
  count = var.external_dns_enabled ? 1 : 0

  name               = "${var.cluster_name}-external-dns"
  assume_role_policy = data.aws_iam_policy_document.external_dns_assume_role[0].json
}

resource "aws_iam_role_policy_attachment" "external_dns" {
  count = var.external_dns_enabled ? 1 : 0

  role       = aws_iam_role.external_dns[0].name
  policy_arn = aws_iam_policy.external_dns[0].arn
}

resource "kubernetes_service_account_v1" "external_dns" {
  count = var.external_dns_enabled ? 1 : 0

  metadata {
    name      = var.external_dns_service_account_name
    namespace = var.external_dns_namespace
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.external_dns[0].arn
    }
    labels = {
      "app.kubernetes.io/name"      = "external-dns"
      "app.kubernetes.io/component" = "controller"
    }
  }

  depends_on = [module.eks]
}

resource "helm_release" "external_dns" {
  count = var.external_dns_enabled ? 1 : 0

  name       = "external-dns"
  repository = "https://kubernetes-sigs.github.io/external-dns/"
  chart      = "external-dns"
  version    = var.external_dns_chart_version
  namespace  = var.external_dns_namespace

  values = [yamlencode({
    provider = {
      name = "aws"
    }
    policy             = "sync"
    registry           = "txt"
    txtOwnerId         = var.cluster_name
    zoneIdFilters      = var.external_dns_hosted_zone_ids
    sources            = ["service", "ingress"]
    triggerLoopOnEvent = true
    serviceAccount = {
      create = false
      name   = var.external_dns_service_account_name
    }
  })]

  depends_on = [
    module.eks,
    kubernetes_service_account_v1.external_dns,
    aws_iam_role_policy_attachment.external_dns,
  ]
}
