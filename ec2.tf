resource "random_pet" "asg_suffix" {
  length = 2
}

resource "random_pet" "single_instance_suffix" {
  length = 2
}

resource "aws_iam_role" "asg_role" {
  name = "asg_role_${random_pet.asg_suffix.id}" # Ensure unique role name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "asg_ssm_policy_attachment" {
  role       = aws_iam_role.asg_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy" "asg_policy" {
  name = "asg_policy"
  role = aws_iam_role.asg_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "s3:GetObject"
        Effect   = "Allow"
        Resource = "arn:aws:s3:::images/*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "asg_instance_profile" {
  name = "asg_instance_profile_${random_pet.asg_suffix.id}" # Ensure unique profile name
  role = aws_iam_role.asg_role.name
}

resource "aws_iam_role" "single_instance_role" {
  name = "single_instance_role_${random_pet.single_instance_suffix.id}" # Ensure unique role name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "single_instance_ssm_policy_attachment" {
  role       = aws_iam_role.single_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "single_instance_profile" {
  name = "single_instance_profile_${random_pet.single_instance_suffix.id}" # Ensure unique profile name
  role = aws_iam_role.single_instance_role.name
}

data "aws_ami" "redhat" {
  most_recent = true
  owners      = ["309956199498"] # Red Hat's owner ID

  filter {
    name   = "name"
    values = ["RHEL-8.*_HVM-*-x86_64-*"]
  }
}

resource "aws_security_group" "example" {
  name_prefix = "example-sg-"
  description = "Security group for example instance"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

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
    Name = "example-sg"
  }
}

module "ec2_instance" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-ec2.git//?ref=master"

  name = "single-instance"

  ami           = data.aws_ami.redhat.id
  instance_type = "t2.micro"

  subnet_id = module.vpc.private_subnets[1]

  vpc_security_group_ids = [aws_security_group.example.id]

  tags = {
    Name = "single-instance"
  }

  root_block_device = [{
    volume_size           = 20
    volume_type           = "gp2"
    delete_on_termination = true
  }]

  iam_instance_profile = aws_iam_instance_profile.single_instance_profile.name
}

resource "aws_launch_template" "asg_launch_template" {
  name = "asg-launch-template-${random_pet.asg_suffix.id}" # Ensure unique template name

  iam_instance_profile {
    name = aws_iam_instance_profile.asg_instance_profile.name
  }

  image_id      = data.aws_ami.redhat.id
  instance_type = "t2.micro"

  user_data = base64encode(<<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd amazon-ssm-agent
              systemctl start httpd
              systemctl enable httpd
              systemctl start amazon-ssm-agent
              systemctl enable amazon-ssm-agent
              EOF
  )

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size = 20
      volume_type = "gp2"
    }
  }
}

resource "aws_autoscaling_group" "example_asg" {
  launch_template {
    id      = aws_launch_template.asg_launch_template.id
    version = "$Latest"
  }

  vpc_zone_identifier = [
    module.vpc.private_subnets[0],
    module.vpc.private_subnets[1]
  ]

  min_size                  = 2
  max_size                  = 6
  desired_capacity          = 2
  health_check_type         = "EC2"
  health_check_grace_period = 300

  tag {
    key                 = "Name"
    value               = "example-instance"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_attachment" "asg_attachment" {
  depends_on             = [aws_autoscaling_group.example_asg]
  autoscaling_group_name = aws_autoscaling_group.example_asg.name
  lb_target_group_arn    = aws_lb_target_group.asg_target_group.arn
}

output "security_group_id" {
  description = "The ID of the security group"
  value       = aws_security_group.example.id
}
