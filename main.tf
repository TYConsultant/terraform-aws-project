provider "aws" {
  region = "us-east-1" # Specify your region
}

module "vpc" {
  source = "git::https://github.com/Coalfire-CF/terraform-aws-vpc-nfw.git"

  vpc_name    = "my-vpc"
  vpc_cidr    = "10.1.0.0/16"
  azs         = ["us-east-1a", "us-east-1b"]

  public_subnets = [
    {
      name = "subnet-1"
      cidr = "10.1.0.0/24"
    },
    {
      name = "subnet-2"
      cidr = "10.1.1.0/24"
    }
  ]

  private_subnets = [
    {
      name = "subnet-3"
      cidr = "10.1.2.0/24"
    },
    {
      name = "subnet-4"
      cidr = "10.1.3.0/24"
    }
  ]

  enable_nat_gateway = true
  single_nat_gateway = true

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
  value       = module.vpc.public_subnet_ids
}

output "private_subnets" {
  description = "The private subnets"
  value       = module.vpc.private_subnet_ids
}
