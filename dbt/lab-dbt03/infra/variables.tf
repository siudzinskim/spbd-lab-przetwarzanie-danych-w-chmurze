variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1" # Choose your preferred region
}

variable "tfstate_bucket_name" {
  type = string
}

