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
