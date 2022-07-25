terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
#  backend "s3" {
#    encrypt        = false
#    bucket         = "tf-bucket-s3"
#    dynamodb_table = "tf-state-lock-dynamo"
#    key            = "terraform-tfstate"
#    region         = "ap-south-1"
#  }
}

variable "aws_region" {
  description = "Region for aws"
}

provider "aws" {
  region     = var.aws_region
}
