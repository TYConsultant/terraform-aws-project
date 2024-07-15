provider "aws" {
  region = "us-east-1" # Adjust the region as per your requirement
}

# Module: VPC
module "vpc" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-vpc.git"

  name               = "my-vpc"
  cidr               = "10.1.0.0/16"
  azs                = ["us-east-1a", "us-east-1b"]
  private_subnets    = ["10.1.2.0/24", "10.1.3.0/24"]
  public_subnets     = ["10.1.0.0/24", "10.1.1.0/24"]
  enable_nat_gateway = true
  single_nat_gateway = true
  enable_vpn_gateway = false

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

# Security Groups
resource "aws_security_group" "public_sg" {
  name        = "public_sg"
  description = "Allow inbound HTTP traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "private_sg" {
  name        = "private_sg"
  description = "Allow inbound traffic from ALB"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "alb_sg" {
  name        = "alb_sg"
  description = "Allow inbound HTTP traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Module: EC2
module "ec2" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-ec2-instance.git"

  name                   = "my-instance"
  ami                    = "ami-0a91cd140a1fc148a" # Red Hat Linux AMI
  instance_type          = "t2.micro"
  subnet_id              = module.vpc.public_subnets[1]
  key_name               = "your-key-name"
  vpc_security_group_ids = [aws_security_group.public_sg.id]

  tags = {
    Name = "MyInstance"
  }
}

resource "aws_ebs_volume" "ec2_storage" {
  availability_zone = "us-east-1a"
  size              = 20

  tags = {
    Name = "EC2Storage"
  }
}

resource "aws_volume_attachment" "ec2_attachment" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.ec2_storage.id
  instance_id = module.ec2.this_instance_id
}

# Module: Auto Scaling Group (ASG)
module "asg" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-autoscaling.git"

  name                      = "my-asg"
  ami                       = "ami-0a91cd140a1fc148a" # Red Hat Linux AMI
  instance_type             = "t2.micro"
  vpc_zone_identifier       = [module.vpc.private_subnets[0], module.vpc.private_subnets[1]]
  min_size                  = 2
  max_size                  = 6
  desired_capacity          = 2
  health_check_type         = "EC2"
  health_check_grace_period = 300
  user_data                 = <<-EOF
                            #!/bin/bash
                            yum install -y httpd
                            systemctl start httpd
                            systemctl enable httpd
                            EOF
  security_groups           = [aws_security_group.private_sg.id]

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
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-alb.git"

  name               = "my-alb"
  load_balancer_type = "application"
  vpc_id             = module.vpc.vpc_id
  subnets            = module.vpc.public_subnets
  security_groups    = [aws_security_group.alb_sg.id]

  target_groups = [
    {
      name             = "my-target-group"
      backend_protocol = "HTTP"
      backend_port     = 80
      target_type      = "instance"
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

  listeners = [
    {
      port     = 80
      protocol = "HTTP"
      default_action = {
        type             = "forward"
        target_group_arn = lookup(module.alb.target_groups, "my-target-group", "arn")
      }
    }
  ]

  tags = {
    Name = "my-alb"
  }
}

# Module: IAM
module "iam" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-iam.git"

  create_role = true
  role_name   = "WebServerRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
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
      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Action = [
              "s3:GetObject",
              "s3:PutObject"
            ]
            Resource = [
              "arn:aws:s3:::images",
              "arn:aws:s3:::images/*",
              "arn:aws:s3:::logs",
              "arn:aws:s3:::logs/*"
            ]
          },
          {
            Effect = "Allow"
            Action = [
              "s3:ListBucket"
            ]
            Resource = [
              "arn:aws:s3:::images",
              "arn:aws:s3:::logs"
            ]
          }
        ]
      })
    }
  ]
}

# Module: S3 for Images
module "s3_images" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-s3-bucket.git"

  bucket_name = "images"
  acl         = "private"

  tags = {
    Name = "images-bucket"
  }
}

# Module: S3 for Logs
module "s3_logs" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-s3-bucket.git"

  bucket_name = "logs"
  acl         = "private"

  tags = {
    Name = "logs-bucket"
  }
}

