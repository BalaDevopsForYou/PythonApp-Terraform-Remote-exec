terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 2.0.0"
    }
  }
}

provider "aws" {
  access_key = "your-access-key"
  secret_key = "your-secret-key"
  region     = "us-east-1"
}