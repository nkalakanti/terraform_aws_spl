terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
  backend "s3" {
    encrypt        = false
    bucket         = "cloudbees-aws-terraform"
    dynamodb_table = "n3_dynamodb"
    key            = "terraform-tfstate"
    region         = "eu-west-1"
  }
}

variable "aws_region" {
  description = "Region for aws"
}

provider "aws" {
  region     = var.aws_region
}
