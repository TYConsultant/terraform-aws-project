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
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 4.0"

  name = "example-instance"

  ami           = "ami-0c41531b8d18cc72b"
  instance_type = "t2.micro"

  subnet_id = module.vpc.private_subnets[1]

  vpc_security_group_ids = [aws_security_group.example.id]

  tags = {
    Name = "example-instance"
  }

  root_block_device = [{
    volume_size           = 20
    volume_type           = "gp2"
    delete_on_termination = true
  }]
}

output "security_group_id" {
  description = "The ID of the security group"
  value       = aws_security_group.example.id
}

