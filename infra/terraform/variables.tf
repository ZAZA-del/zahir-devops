variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "aws_account_id" {
  description = "AWS account ID"
  type        = string
  default     = "143575007958"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "zahir-cluster"
}

variable "k8s_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.30"
}

variable "node_instance_type" {
  description = "EC2 instance type for EKS nodes"
  type        = string
  default     = "t3.medium"
}

variable "node_desired" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "node_min" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "node_max" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 3
}

variable "backend_lb_url" {
  description = "Backend Spring Boot LoadBalancer hostname (used by Lambda + output)"
  type        = string
  default     = ""
}

variable "frontend_lb_url" {
  description = "Frontend Angular LoadBalancer URL (set by CI after kubectl deploy)"
  type        = string
  default     = ""
}

variable "kibana_lb_url" {
  description = "Kibana LoadBalancer URL (set by CI after kubectl deploy)"
  type        = string
  default     = ""
}
