module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.project}-${var.env}"
  cidr = var.vpc_cidr

  azs             = [for x in var.az_cidr : x.az]
  private_subnets = [for x in var.az_cidr : x.private_subnet]
  public_subnets  = [for x in var.az_cidr : x.public_subnet]

  enable_nat_gateway = true
  single_nat_gateway = true
}
