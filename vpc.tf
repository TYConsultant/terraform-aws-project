provider "aws" {
  region = "us-east-1" 
}

module "vpc" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-vpc.git//?ref=master"

  name                 = "ty-vpc"
  cidr                 = "10.1.0.0/16"
  azs                  = ["us-east-1a", "us-east-1b"]
  private_subnets      = ["10.1.2.0/24", "10.1.3.0/24"]
  public_subnets       = ["10.1.0.0/24", "10.1.1.0/24"]
  enable_dns_support   = true
  enable_dns_hostnames = true
  enable_nat_gateway   = true

  tags = {
    Name = "my-vpc"
  }
}

# Outputs to verify the configuration
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnets" {
  description = "The public subnets"
  value       = module.vpc.public_subnets
}

output "private_subnets" {
  description = "The private subnets"
  value       = module.vpc.private_subnets
}

