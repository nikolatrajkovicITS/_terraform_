terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    rediscloud = {
      source  = "RedisLabs/rediscloud"
      version = "0.2.1"
    }
  }
}

provider "aws" {
  region     = var.region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  profile    = "vscode_mac"
}

provider "rediscloud" {
  api_key = var.rediscloud_api_key
}

