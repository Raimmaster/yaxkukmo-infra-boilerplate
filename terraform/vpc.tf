module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "yaxkukmo-vpc"
  cidr = var.cidr_block

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  enable_nat_gateway   = true
  enable_dns_hostnames = true

  tags = {
    Terraform   = "true"
    Environment = terraform.workspace
    Project     = "yaxkukmo"
  }
}