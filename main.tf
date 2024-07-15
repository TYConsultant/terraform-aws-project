provider "aws" {
  region = "us-east-1"  
}

# Module: VPC
module "vpc" {
  source = "git@github.com:Coalfire-CF/terraform-aws-vpc.git"

  cidr_block          = "10.1.0.0/16"
  azs                 = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets     = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
  public_subnets      = ["10.1.4.0/24", "10.1.5.0/24", "10.1.6.0/24"]
  enable_nat_gateway  = true
  single_nat_gateway  = true
  enable_vpn_gateway  = false
  tags = {
    Terraform  = "true"
    Environment = "dev"
  }
}

# Module: EC2
module "ec2" {
  source = "git@github.com:Coalfire-CF/terraform-aws-ec2.git"

  ami           = "ami-0583d8c7a9c35822c"
  instance_type = "t3.micro"
  subnet_id     = module.vpc.private_subnets[0]
  key_name      = "ty_key""
  vpc_security_group_ids = [module.vpc.default_security_group_id]

  tags = {
    Name = "MyInstance"
  }
}

# Module: Auto Scaling Group (ASG)
module "asg" {
  source = "git@github.com:Coalfire-CF/terraform-aws-asg.git"

  launch_configuration    = module.ec2.launch_configuration_name
  min_size                = 2
  max_size                = 6
  desired_capacity        = 2
  vpc_zone_identifier     = module.vpc.private_subnets
  health_check_type       = "EC2"
  health_check_grace_period = 300

  tags = [
    {
      key                 = "Name"
      value               = "my-asg-instance"
      propagate_at_launch = true
    }
  ]
}

# Module: Application Load Balancer (ALB)
module "alb" {
  source = "git@github.com:Coalfire-CF/terraform-aws-alb.git"

  vpc_id            = module.vpc.vpc_id
  subnets           = module.vpc.public_subnets
  load_balancer_type = "application"

  target_groups = [
    {
      name               = "my-target-group"
      backend_protocol   = "HTTP"
      backend_port       = 80
      target_type        = "instance"
      deregistration_delay = 300
      health_check = {
        path                = "/"
        matcher             = "200"
        interval            = 30
        timeout             = 10
        healthy_threshold   = 2
        unhealthy_threshold = 2
      }
    }
  ]

  tags = {
    Name = "my-alb"
  }
}

# Module: IAM
module "iam" {
  source = "git@github.com:Coalfire-CF/terraform-aws-iam.git"

  create_role         = true
  role_name           = "WebServerRole"
  assume_role_policy  = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  attach_policy_arns = ["arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"]

  custom_policy = [
    {
      name        = "S3AccessPolicy"
      description = "Allows read from 'Images' bucket and write to 'Logs' bucket"
      policy      = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect   = "Allow"
            Action   = [
              "s3:GetObject",
              "s3:PutObject"
            ]
            Resource = [
              module.s3.bucket_arn,
              "${module.s3.bucket_arn}/*"
            ]
          },
          {
            Effect   = "Allow"
            Action   = [
              "s3:ListBucket"
            ]
            Resource = [
              module.s3.bucket_arn
            ]
          }
        ]
      })
    }
  ]
}

# Module: S3
module "s3" {
  source = "git@github.com:Coalfire-CF/terraform-aws-s3.git"

  bucket_name     = "images"
  acl             = "private"

  lifecycle_rules = [
    {
      id              = "MoveToGlacier"
      enabled         = true
      transition_days = 90
      storage_class   = "GLACIER"
    }
  ]

  tags = {
    Name = "images-bucket"
  }
}

