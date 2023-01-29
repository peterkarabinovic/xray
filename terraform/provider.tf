terraform {
  required_version = ">= 0.13.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.36.1"
    }
  }

}

provider "aws" {
  region = "eu-central-1"
  profile = "personal"
}
