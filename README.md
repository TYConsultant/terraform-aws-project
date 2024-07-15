Terraform AWS Infrastructure Project
This project provisions AWS infrastructure using Terraform modules sourced from the Coalfire-CF GitHub repositories. The infrastructure includes a VPC, EC2 instances, an Auto Scaling Group, an Application Load Balancer, IAM roles and policies, and an S3 bucket.

Prerequisites
Before you begin, ensure you have the following installed on your machine:

Terraform (v1.0 or later)
AWS CLI (configured with appropriate credentials)
An AWS account with necessary permissions


├── main.tf        # Main Terraform configuration file
├── outputs.tf     # Outputs of the Terraform configuration
├── providers.tf   # Provider configuration
├── variables.tf   # Variables used in the configuration
├── README.md      # This README file
