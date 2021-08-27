locals {
  cluster_name = "eks-terraform-cluster"
}

data "aws_availability_zones" "all" {}


module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "vpc-terraform-eks"
  cidr = "15.0.0.0/16"

  # azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  azs             = data.aws_availability_zones.all.names
  private_subnets = ["15.0.1.0/24", "15.0.2.0/24", "15.0.3.0/24"]
  public_subnets  = ["15.0.101.0/24", "15.0.102.0/24", "15.0.103.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = true

  tags = {
    Terraform                                     = "true"
    Environment                                   = "dev"
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
  }
}

module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = local.cluster_name
  cluster_version = "1.21"
  vpc_id          = module.vpc.vpc_id
  subnets         = module.vpc.private_subnets

  worker_groups = [
    {
      instance_type = "t2.small"
      asg_max_size  = 3
    }
  ]
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}
