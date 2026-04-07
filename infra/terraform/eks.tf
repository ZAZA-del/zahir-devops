# ---------------------------------------------------------------------------
# EKS Cluster
# Import command:
#   terraform import aws_eks_cluster.main zahir-cluster
# ---------------------------------------------------------------------------
resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster.arn
  version  = var.k8s_version

  # eksctl sets this to false; must match to avoid forced cluster replacement
  bootstrap_self_managed_addons = false

  vpc_config {
    subnet_ids = [
      aws_subnet.public_1b.id,
      aws_subnet.public_1f.id,
      aws_subnet.private_1b.id,
      aws_subnet.private_1f.id,
    ]
    # cluster_security_group_id is read-only — EKS manages it automatically
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
    aws_subnet.public_1b.id,
    aws_subnet.public_1f.id,
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
    ignore_changes = [
      tags, tags_all,
      scaling_config[0].desired_size,
      # eksctl manages node labels and launch_template — don't touch them
      labels,
      launch_template,
    ]
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node,
    aws_iam_role_policy_attachment.eks_cni,
    aws_iam_role_policy_attachment.eks_ecr_readonly,
  ]
}
