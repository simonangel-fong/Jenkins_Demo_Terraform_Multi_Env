module "aws_pvc" {
  source = "./modules/vpc"

  vpc_name = "${var.project}-${var.env}"
  vpc_cidr = var.vpc_cidr
  az_cidr  = var.az_cidr
}
