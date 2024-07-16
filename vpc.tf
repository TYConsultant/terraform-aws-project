provider "aws" {
  region = "us-east-1" 
}

module "vpc" {
  source = "git::https://github.com/Coalfire-CF/terraform-aws-vpc-nfw.git"

  cidr = "10.1.0.0/16"
  azs  = ["us-east-1a", "us-east-1b"]

  private_subnets = {
    "subnet-3" = "10.1.2.0/24",
    "subnet-4" = "10.1.3.0/24"
  }

  public_subnets = {
    "subnet-1" = "10.1.0.0/24",
    "subnet-2" = "10.1.1.0/24"
  }

  single_nat_gateway     = true
  enable_nat_gateway     = true
  enable_vpn_gateway     = false
  enable_dns_hostnames   = true
  enable_dns_support     = true

  flow_log_destination_type              = "cloud-watch-logs"
  cloudwatch_log_group_retention_in_days = 30
  cloudwatch_log_group_kms_key_id        = "" 

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

