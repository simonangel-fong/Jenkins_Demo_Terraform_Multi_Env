# variables.tf
# ##############################
# Project
# ##############################
variable "project" {
  description = "Project name"
  type        = string
  default     = "jenkins-terraform"
}

variable "env" {
  type = string
}

# ##############################
# AWS
# ##############################
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ca-central-1"
}

# ##############################
# VPC
# ##############################
variable "vpc_cidr" {
  description = "VPC Cidr"
  type        = string
  default     = "10.0.0.0/16"
}

variable "az_cidr" {
  type = list(object({
    az             = string,
    private_subnet = string,
    public_subnet  = string
  }))
  default = [
    {
      az             = "ca-central-1a",
      private_subnet = "10.0.1.0/24",
      public_subnet  = "10.0.101.0/24"
    },
    {
      az             = "ca-central-1b",
      private_subnet = "10.0.2.0/24",
      public_subnet  = "10.0.102.0/24"
    }
  ]
}
