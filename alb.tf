resource "aws_iam_role" "alb_role" {
  name = "alb_role"

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
}

resource "aws_iam_role_policy" "alb_policy" {
  name = "alb_policy"
  role = aws_iam_role.alb_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "s3:PutObject"
        Effect   = "Allow"
        Resource = "arn:aws:s3:::log-bucket/*"
      }
    ]
  })
}

resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Security group for ALB"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "alb-sg"
  }
}

module "alb" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-alb.git"

  name               = "application-load-balancer"
  load_balancer_type = "application"
  vpc_id             = module.vpc.vpc_id
  subnets            = module.vpc.public_subnets

  security_groups = [aws_security_group.alb_sg.id]

  listeners = [
    {
      port     = 80
      protocol = "HTTP"
      default_action = {
        type               = "forward"
        target_group_index = 0
      }
    }
  ]

  target_groups = [
    {
      name_prefix      = "tytg"
      backend_protocol = "HTTPS"
      port             = 443
      target_type      = "instance"
      vpc_id           = module.vpc.vpc_id

      health_check = {
        enabled             = true
        path                = "/"
        protocol            = "HTTPS"
        matcher             = "200"
        interval            = 30
        timeout             = 5
        healthy_threshold   = 2
        unhealthy_threshold = 2
      }
    }
  ]

  tags = {
    Name = "application-load-balancer"
  }
}

resource "aws_autoscaling_attachment" "asg_attachment" {
  autoscaling_group_name = aws_autoscaling_group.example_asg.name
  lb_target_group_arn    = module.alb.target_groups[0].arn
}
