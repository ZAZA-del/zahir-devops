# ---------------------------------------------------------------------------
# EKS Cluster
# Import command:
#   terraform import aws_eks_cluster.main zahir-cluster
# ---------------------------------------------------------------------------
resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster.arn
  version  = var.k8s_version

  vpc_config {
    subnet_ids = [
      "subnet-0af9da2aa1bda019d",
      "subnet-09316561ce8129bce",
      "subnet-04947bfff2536a195",
      "subnet-00e80835781aa3152",
    ]
    # Cluster security group is auto-managed by EKS — reference only, not created here
    cluster_security_group_id = "sg-0fe5f2b9498e285cf"
  }

  # eksctl adds its own tags; ignore them to prevent spurious diffs
  lifecycle {
    ignore_changes = [tags, tags_all, vpc_config[0].security_group_ids]
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_iam_role_policy_attachment.eks_vpc_controller,
  ]
}

# ---------------------------------------------------------------------------
# EKS Managed Node Group
# Import command:
#   terraform import aws_eks_node_group.main zahir-cluster:zahir-nodes
# ---------------------------------------------------------------------------
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "zahir-nodes"
  node_role_arn   = aws_iam_role.eks_node.arn
  ami_type        = "AL2023_x86_64_STANDARD"

  subnet_ids = [
    data.aws_subnet.node_1.id,
    data.aws_subnet.node_2.id,
  ]

  instance_types = [var.node_instance_type]

  scaling_config {
    desired_size = var.node_desired
    min_size     = var.node_min
    max_size     = var.node_max
  }

  update_config {
    max_unavailable = 1
  }

  lifecycle {
    ignore_changes = [tags, tags_all, scaling_config[0].desired_size]
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node,
    aws_iam_role_policy_attachment.eks_cni,
    aws_iam_role_policy_attachment.eks_ecr_readonly,
  ]
}
