variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "eks-workshop"
}

variable "cluster_version" {
  description = "EKS cluster version."
  type        = string
  default     = "1.33"
}

variable "ami_release_version" {
  description = "Default EKS AMI release version for node groups"
  type        = string
  default     = "1.33.0-20250704"
}

variable "vpc_cidr" {
  description = "Defines the CIDR block used on Amazon VPC created for Amazon EKS."
  type        = string
  default     = "10.42.0.0/16"
}

variable "remote_network_cidr" {
  description = "Defines the remote CIDR blocks used on Amazon VPC created for Amazon EKS Hybrid Nodes."
  type        = string
  default     = "10.52.0.0/16"
}

variable "remote_pod_cidr" {
  description = "Defines the remote CIDR blocks used on Amazon VPC created for Amazon EKS Hybrid Nodes."
  type        = string
  default     = "10.53.0.0/16"
}

variable "aws_load_balancer_controller_namespace" {
  description = "Namespace for AWS Load Balancer Controller"
  type        = string
  default     = "kube-system"
}

variable "aws_load_balancer_controller_service_account_name" {
  description = "Service account name for AWS Load Balancer Controller"
  type        = string
  default     = "aws-load-balancer-controller"
}

variable "aws_load_balancer_controller_chart_version" {
  description = "Helm chart version for AWS Load Balancer Controller"
  type        = string
  default     = "1.11.0"
}

variable "cluster_autoscaler_namespace" {
  description = "Namespace for Cluster Autoscaler"
  type        = string
  default     = "kube-system"
}

variable "cluster_autoscaler_service_account_name" {
  description = "Service account name for Cluster Autoscaler"
  type        = string
  default     = "cluster-autoscaler"
}

variable "cluster_autoscaler_chart_version" {
  description = "Helm chart version for Cluster Autoscaler"
  type        = string
  default     = "9.57.0"
}

variable "cluster_autoscaler_image_tag" {
  description = "Container image tag for Cluster Autoscaler"
  type        = string
  default     = "v1.33.3"
}

variable "metrics_server_namespace" {
  description = "Namespace for Metrics Server"
  type        = string
  default     = "kube-system"
}

variable "metrics_server_service_account_name" {
  description = "Service account name for Metrics Server"
  type        = string
  default     = "metrics-server"
}

variable "metrics_server_chart_version" {
  description = "Helm chart version for Metrics Server"
  type        = string
  default     = "3.13.0"
}

variable "metrics_server_image_tag" {
  description = "Container image tag for Metrics Server"
  type        = string
  default     = "v0.8.0"
}

variable "external_dns_enabled" {
  description = "Whether to deploy ExternalDNS"
  type        = bool
  default     = false
}

variable "external_dns_namespace" {
  description = "Namespace for ExternalDNS"
  type        = string
  default     = "kube-system"
}

variable "external_dns_service_account_name" {
  description = "Service account name for ExternalDNS"
  type        = string
  default     = "external-dns"
}

variable "external_dns_chart_version" {
  description = "Helm chart version for ExternalDNS"
  type        = string
  default     = "1.20.0"
}

variable "external_dns_hosted_zone_ids" {
  description = "Route53 hosted zone IDs managed by ExternalDNS"
  type        = list(string)
  default     = []

  validation {
    condition     = !var.external_dns_enabled || length(var.external_dns_hosted_zone_ids) > 0
    error_message = "Set external_dns_hosted_zone_ids to at least one Route53 hosted zone ID when external_dns_enabled is true."
  }
}
