# module/vpc/variables.tf
variable "vpc_name" {
  description = "VPC name"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC Cidr"
  type        = string
}

variable "az_cidr" {
  description = "AZ to subnet CIDR mapping"
  type = list(object({
    az             = string
    private_subnet = string
    public_subnet  = string
  }))

  validation {
    condition     = length(var.az_cidr) > 0
    error_message = "az_cidr must contain at least one AZ definition."
  }
}
