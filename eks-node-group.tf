resource "aws_eks_node_group" "eks-demo-cluster-ng" {
  cluster_name    = aws_eks_cluster.eks-demo-cluster.name
  node_group_name = "eks-demo-cluster-ng"
  node_role_arn   = aws_iam_role.eks-demo-cluster-ng.arn
  subnet_ids      = module.vpc.private_subnets
  instance_types  = ["t3.medium"]
  tags = merge(var.default_tags, map("Name", "eks-demo-cluster-ng"))
  scaling_config {
    desired_size = 1
    max_size     = 1
    min_size     = 1
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.eks-demo-cluster-ng-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.eks-demo-cluster-ng-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.eks-demo-cluster-ng-AmazonEC2ContainerRegistryReadOnly,
  ]
}

# Workaround for tagging AWS Managed EKS nodegroups
locals {
  asg_name = aws_eks_node_group.eks-demo-cluster-ng.resources[0]["autoscaling_groups"][0]["name"]
}

resource "null_resource" "add_custom_tags_to_asg" {
  triggers = {
    node_group = local.asg_name
  }
  provisioner "local-exec" {
    command = <<EOF
aws autoscaling create-or-update-tags \
  --tags ResourceId=${local.asg_name},ResourceType=auto-scaling-group,Key="Name",Value="EKS-MANAGED-NODEGROUP-NODE",PropagateAtLaunch=true
aws autoscaling create-or-update-tags \
  --tags ResourceId=${local.asg_name},ResourceType=auto-scaling-group,Key="Custodian-Scheduler-StopTime",Value="off",PropagateAtLaunch=true
EOF
  }

  depends_on = [
    aws_eks_node_group.eks-demo-cluster-ng
  ]
}
