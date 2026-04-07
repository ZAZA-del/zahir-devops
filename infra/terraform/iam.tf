# ---------------------------------------------------------------------------
# EKS Cluster IAM Role
# Originally created by eksctl. Imported into Terraform state.
# Import command:
#   terraform import aws_iam_role.eks_cluster \
#     eksctl-zahir-cluster-cluster-ServiceRole-Ihp1DCeusPbU
# ---------------------------------------------------------------------------
resource "aws_iam_role" "eks_cluster" {
  name = "eksctl-zahir-cluster-cluster-ServiceRole-Ihp1DCeusPbU"

  # Trust policy as returned by AWS (includes sts:TagSession added by eksctl)
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
      Action    = ["sts:AssumeRole", "sts:TagSession"]
    }]
  })

  lifecycle {
    ignore_changes = [tags, tags_all]
  }
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "eks_vpc_controller" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
}

# ---------------------------------------------------------------------------
# EKS Node Group IAM Role
# Originally created by eksctl. Imported into Terraform state.
# Import command:
#   terraform import aws_iam_role.eks_node \
#     eksctl-zahir-cluster-nodegroup-zah-NodeInstanceRole-NILYKChlXvKS
# ---------------------------------------------------------------------------
resource "aws_iam_role" "eks_node" {
  name = "eksctl-zahir-cluster-nodegroup-zah-NodeInstanceRole-NILYKChlXvKS"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  lifecycle {
    ignore_changes = [tags, tags_all]
  }
}

resource "aws_iam_role_policy_attachment" "eks_worker_node" {
  role       = aws_iam_role.eks_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cni" {
  role       = aws_iam_role.eks_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "eks_ecr_readonly" {
  role       = aws_iam_role.eks_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "eks_ecr_pull_only" {
  role       = aws_iam_role.eks_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPullOnly"
}

resource "aws_iam_role_policy_attachment" "eks_ssm" {
  role       = aws_iam_role.eks_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# ---------------------------------------------------------------------------
# Lambda IAM Role
# Import command:
#   terraform import aws_iam_role.lambda zahir-lambda-role
# ---------------------------------------------------------------------------
resource "aws_iam_role" "lambda" {
  name = "zahir-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
