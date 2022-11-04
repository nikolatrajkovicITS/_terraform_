terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region     = "us-east-1"
  access_key = "AKIAX2LT2VYAMLNP2EU6"
  secret_key = "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"
  profile    = "vscode_mac"
}

