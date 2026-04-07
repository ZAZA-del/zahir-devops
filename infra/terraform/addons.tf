# ---------------------------------------------------------------------------
# EKS Managed Add-ons
#
# Required because bootstrap_self_managed_addons = false on the cluster,
# so EKS does NOT install VPC CNI, kube-proxy, or CoreDNS automatically.
# Without these, nodes stay NotReady (NetworkPluginNotReady) and the
# node group reaches CREATE_FAILED.
#
# These are EKS-managed (not eksctl-managed), installed via the EKS API.
# AWS patches them automatically with cluster version upgrades.
# ---------------------------------------------------------------------------

resource "aws_eks_addon" "vpc_cni" {
  cluster_name  = aws_eks_cluster.main.name
  addon_name    = "vpc-cni"
  # resolve_conflicts_on_create = "OVERWRITE" allows addon install even if
  # self-managed resources exist in kube-system from a prior deployment.
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE"

  depends_on = [aws_eks_cluster.main]
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "kube-proxy"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE"

  depends_on = [aws_eks_cluster.main]
}

resource "aws_eks_addon" "coredns" {
  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "coredns"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE"

  # CoreDNS requires nodes to be Ready before it can schedule.
  # Depend on the node group so CoreDNS waits until nodes exist.
  depends_on = [aws_eks_node_group.main]
}
