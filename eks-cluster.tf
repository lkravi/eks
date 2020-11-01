resource "aws_eks_cluster" "eks-demo-cluster" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks-demo-cluster.arn
  tags = merge(var.default_tags, map("Name", "eks-demo-cluster"))
  vpc_config {
    security_group_ids = [aws_security_group.eks-demo-cluster.id]
    subnet_ids = module.vpc.private_subnets
    endpoint_private_access = "true"
    endpoint_public_access = "true"
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks-demo-cluster-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.eks-demo-cluster-AmazonEKSServicePolicy,
  ]
}
