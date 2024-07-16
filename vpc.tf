provider "aws" {
  alias  = "mgmt"
  region = var.aws_region
}

module "mgmt_vpc" {
  source = "github.com/Coalfire-CF/terraform-aws-vpc-nfw"
  providers = {
    aws = aws.mgmt
  }

  name = "${var.resource_prefix}-mgmt"

  delete_protection = var.delete_protection

  cidr = var.mgmt_vpc_cidr

  azs = [
    data.aws_availability_zones.available.names[0],
    data.aws_availability_zones.available.names[1]
  ]

  private_subnets = {
    "ty-subnet-3" = "10.1.2.0/24"
    "ty-subnet-4" = "10.1.3.0/24"
  }

  public_subnets = {
    "ty-subnet-1" = "10.1.0.0/24"
    "ty-subnet-2" = "10.1.1.0/24"
  }
  public_subnet_suffix = "public"

  single_nat_gateway     = false
  enable_nat_gateway     = true
  one_nat_gateway_per_az = true
  enable_vpn_gateway     = false
  enable_dns_hostnames   = true

  flow_log_destination_type              = "cloud-watch-logs"
  cloudwatch_log_group_retention_in_days = 30
  cloudwatch_log_group_kms_key_id        = data.terraform_remote_state.day0.outputs.cloudwatch_kms_key_arn

  /* Add Additional tags here */
  tags = {
    Owner       = var.resource_prefix
    Environment = "mgmt"
    createdBy   = "terraform"
  }
}
