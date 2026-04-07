# Reference the VPC created by eksctl — Terraform does not manage the VPC itself.
# The VPC was auto-provisioned by eksctl and is referenced here for subnet lookups.
data "aws_vpc" "eks" {
  id = "vpc-04031749c8b836ba7"
}

# Node-group subnets (public, used by worker nodes)
data "aws_subnet" "node_1" {
  id = "subnet-0af9da2aa1bda019d" # us-east-1b public
}

data "aws_subnet" "node_2" {
  id = "subnet-09316561ce8129bce" # us-east-1f public
}
