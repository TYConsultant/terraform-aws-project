variable "resource_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "delete_protection" {
  description = "Whether to enable delete protection for the VPC"
  type        = bool
  default     = false
}

variable "mgmt_vpc_cidr" {
  description = "CIDR block for the management VPC"
  type        = string
  default     = "10.1.0.0/16"
}

variable "aws_region" {
  description = "AWS region to deploy resources in"
  type        = string
  default     = "us-east-1"
}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  private_subnets = {
    "ty-subnet-3" = "10.1.2.0/24"
    "ty-subnet-4" = "10.1.3.0/24"
  }

  public_subnets = {
    "ty-subnet-1" = "10.1.0.0/24"
    "ty-subnet-2" = "10.1.1.0/24"
  }
}

data "terraform_remote_state" "day0" {
  backend = "s3"

  config = {
    bucket = "your-s3-bucket"
    key    = "path/to/remote/state"
    region = "us-east-1"
  }
}
