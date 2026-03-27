terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

  }

  backend "s3" {
    bucket = "spbd-siudzinskim-tfstate" # Zastąp nazwą bucketu z lab 1
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region  = "us-east-1" # Frankfurt
  profile = "default"
}
