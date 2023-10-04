provider "aws" {
  region = "us-east-1"
}

module "vpc" {
  source          = "terraform-aws-modules/vpc/aws"
  name            = "my-eks-vpc"
  cidr            = "10.0.0.0/16"
  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  map_public_ip_on_launch = true

}

resource "aws_eks_cluster" "my-cluster" {
  name     = "my-eks-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids = module.vpc.public_subnets
  }
  depends_on = [
    aws_iam_role.eks_cluster_role
  ]

}

resource "aws_eks_node_group" "my-node-group" {
  cluster_name = aws_eks_cluster.my-cluster.name
  node_group_name = "my-node-group"

  node_role_arn = aws_iam_role.eks_node_group_role.arn
  subnet_ids    = module.vpc.public_subnets
  scaling_config {
    desired_size = 2  # Adjust the desired number of nodes as needed
    max_size     = 3  # Adjust the maximum number of nodes as needed
    min_size     = 1  # Adjust the minimum number of nodes as needed
  }
  launch_template {
    id = aws_launch_template.my-launch-template.id
    version = "$Latest"  # Use the latest version of the launch template
  }
  depends_on = [
    aws_iam_role.eks_node_group_role
  ]
}

resource "aws_launch_template" "my-launch-template" {
  name_prefix   = "my-launch-template-"
  
  # Define the instance type and other launch template settings
  # Adjust these values according to your requirements
  instance_type = "t2.micro"
  
  # Add other launch template configurations as needed
}

resource "aws_iam_role" "eks_cluster_role" {
  name = "eks-cluster-role"

  # Define the assume_role_policy for the cluster role
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })

}

resource "aws_iam_role" "eks_node_group_role" {
  name = "eks-node-group-role"

  # Define the assume_role_policy for the node group role
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Attach the required Amazon EKS managed policies
resource "aws_iam_policy_attachment" "eks_node_group_worker_node_policy" {
  name       = "example-worker-node-policy-attachment"
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  roles      = [aws_iam_role.eks_node_group_role.name]
}

resource "aws_iam_policy_attachment" "eks_node_group_ecr_readonly_policy" {
  name        = "example-ecr-readonly-policy-attachment" # Provide a unique name here
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  roles      = [aws_iam_role.eks_node_group_role.name]
}

resource "aws_iam_policy_attachment" "eks_cluster_policy_attachment" {
  name       = "example-eks-cluster-policy-attachment"
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  roles      = [aws_iam_role.eks_cluster_role.name] # Replace with your EKS cluster role name
}

resource "aws_iam_policy_attachment" "eks_cluster_CNI_policy_attachment" {
  name       = "example-eks-cluster-policy-attachment"
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  roles      = [aws_iam_role.eks_cluster_role.name] # Replace with your EKS cluster role name
}


