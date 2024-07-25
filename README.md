Terraform AWS Infrastructure Project
This project provisions AWS infrastructure using Terraform modules sourced from the AWS/Terraform GitHub repositories. The infrastructure includes a VPC, EC2 instances, an Auto Scaling Group, an Application Load Balancer, IAM roles and policies, and an S3 bucket.

Prerequisites
Before you begin, ensure you have the following installed on your machine:

Terraform (v1.0 or later)
AWS CLI (configured with appropriate credentials)
An AWS account with necessary permissions

GitHub Actions Pipeline
This project utilizes GitHub Actions for CI/CD automation. The pipeline is triggered on pushes to the dev branch and pull requests targeting the main branch.

Useful links
https://access.redhat.com/solutions/15356
https://github.com/terraform-aws-modules


