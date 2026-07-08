terraform {
  required_version = ">= 1.6.0"

  # Replace with your own state bucket (do not reuse gitops-platform-tfstate-<acct-id>,
  # keep this project's state isolated so the two clusters can be destroyed independently)
  backend "s3" {
    bucket = "robot-shop-tfstate-928535088615"
    key    = "robot-shop/eks/terraform.tfstate"
    region = "us-east-1"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  cluster_name = "robot-shop-eks"
  azs          = slice(data.aws_availability_zones.available.names, 0, 2)
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${local.cluster_name}-vpc"
  cidr = "10.20.0.0/16"

  azs             = local.azs
  private_subnets = ["10.20.1.0/24", "10.20.2.0/24"]
  public_subnets  = ["10.20.101.0/24", "10.20.102.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true # cost saver — one NAT for both AZs
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = local.cluster_name
  cluster_version = var.kubernetes_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  cluster_endpoint_public_access = true

  eks_managed_node_groups = {
    default = {
      # Robot Shop is 12 services (incl. mongo/mysql/redis/rabbitmq) — more resource-hungry
      # than a control-plane-only demo cluster, so sized up from t3.small.
      instance_types = [var.node_instance_type]
      min_size       = 2
      max_size       = 4
      desired_size   = var.desired_node_count
    }
  }

  enable_cluster_creator_admin_permissions = true

  tags = {
    Project = "robot-shop"
  }
}
