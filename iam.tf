#EKS Cluster
resource "aws_iam_role" "eks-demo-cluster" {
  name = "eks-demo-cluster"
  tags = merge(var.default_tags, map("Name", "eks-demo-cluster-sg"))
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "eks-demo-cluster-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks-demo-cluster.name
}

resource "aws_iam_role_policy_attachment" "eks-demo-cluster-AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.eks-demo-cluster.name
}

resource "aws_security_group" "eks-demo-cluster" {
  name        = "terraform-eks-demo-cluster"
  description = "Cluster communication with worker nodes"
  vpc_id      = module.vpc.vpc_id
  tags = merge(var.default_tags, map("Name", "eks-demo-cluster-sg"))
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#NodeGroup
resource "aws_iam_role" "eks-demo-cluster-ng" {
  name = "eks-demo-cluster-node-group"
  tags = merge(var.default_tags, map("Name", "eks-demo-cluster-ng-sg"))
  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "eks-demo-cluster-ng-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks-demo-cluster-ng.name
}

resource "aws_iam_role_policy_attachment" "eks-demo-cluster-ng-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks-demo-cluster-ng.name
}

resource "aws_iam_role_policy_attachment" "eks-demo-cluster-ng-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks-demo-cluster-ng.name
}
